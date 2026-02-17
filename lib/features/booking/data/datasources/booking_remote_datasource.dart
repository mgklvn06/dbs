import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/core/services/appointment_policy_service.dart';
import '../models/appointment_model.dart';

abstract class BookingRemoteDataSource {
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<List<AppointmentModel>> getAppointmentsForUser(String userId);
  Future<List<AppointmentModel>> getAppointmentsForDoctor(String doctorId);
  Future<List<AppointmentModel>> getAllAppointments();
  Future<void> updateAppointmentStatus(String appointmentId, String status);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;
  static const Set<String> _nonBlockingStatuses = {'cancelled', 'rejected'};
  final AppointmentPolicyService _policyService;

  BookingRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance,
        _policyService = AppointmentPolicyService(firestore: firestore ?? FirebaseFirestore.instance);

  Future<_BookingPolicy> _loadPolicy() async {
    final settingsSnap = await firestore.collection('settings').doc('system').get();
    final settings = settingsSnap.data() ?? <String, dynamic>{};

    Map<String, dynamic> readMap(dynamic raw) {
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) {
        return raw.map((k, v) => MapEntry('$k', v));
      }
      return <String, dynamic>{};
    }

    int readInt(dynamic raw, int fallback) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? fallback;
      return fallback;
    }

    final maintenance = readMap(settings['maintenance']);
    final booking = readMap(settings['booking']);
    final maintenanceEnabled = (maintenance['enabled'] as bool?) ?? (settings['maintenanceMode'] as bool?) ?? false;
    final bookingEnabled = (booking['enabled'] as bool?) ?? true;
    final autoConfirm = (booking['autoConfirm'] as bool?) ?? false;
    final minNoticeHours = readInt(booking['minNoticeHours'], 2);
    final maxPatientPerDay = readInt(booking['maxBookingsPerPatientPerDay'], 2);
    final maxDoctorPerDay = readInt(booking['maxBookingsPerDoctorPerDay'], 15);
    final maintenanceMessage =
        (maintenance['message'] as String?) ?? 'System is under maintenance. Please try again later.';
    final bookingDisabledMessage = maintenanceEnabled
        ? maintenanceMessage
        : 'Booking is currently disabled by the admin.';

    return _BookingPolicy(
      bookingEnabled: bookingEnabled && !maintenanceEnabled,
      bookingDisabledMessage: bookingDisabledMessage,
      autoConfirm: autoConfirm,
      minNoticeHours: minNoticeHours < 0 ? 0 : minNoticeHours,
      maxBookingsPerPatientPerDay: maxPatientPerDay < 0 ? 0 : maxPatientPerDay,
      maxBookingsPerDoctorPerDay: maxDoctorPerDay < 0 ? 0 : maxDoctorPerDay,
    );
  }

  CollectionReference<AppointmentModel> get _col => firestore.collection('appointments').withConverter<AppointmentModel>(
        fromFirestore: (snap, _) => AppointmentModel.fromMap(snapshotMapToMap(snap.data())),
        toFirestore: (AppointmentModel model, _) => model.toMap(),
      );

  // Helper to ensure a Map<String, dynamic> is available for fromMap
  Map<String, dynamic> snapshotMapToMap(Map<String, dynamic>? maybeMap) {
    return maybeMap ?? <String, dynamic>{};
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final policy = await _loadPolicy();
    if (!policy.bookingEnabled) {
      throw Exception(policy.bookingDisabledMessage);
    }

    final now = DateTime.now();
    final minBookTime = now.add(Duration(hours: policy.minNoticeHours));
    if (appointment.dateTime.isBefore(minBookTime)) {
      throw Exception('Booking requires at least ${policy.minNoticeHours} hour(s) notice.');
    }

    final dayStart = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (policy.maxBookingsPerPatientPerDay > 0) {
      final patientCount = await _countBookingsForDay(
        field: 'userId',
        id: appointment.userId,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );
      if (patientCount >= policy.maxBookingsPerPatientPerDay) {
        throw Exception(
          'You have reached the daily booking limit (${policy.maxBookingsPerPatientPerDay}).',
        );
      }
    }

    if (policy.maxBookingsPerDoctorPerDay > 0) {
      final doctorCount = await _countBookingsForDay(
        field: 'doctorId',
        id: appointment.doctorId,
        dayStart: dayStart,
        dayEnd: dayEnd,
      );
      if (doctorCount >= policy.maxBookingsPerDoctorPerDay) {
        throw Exception('Doctor is fully booked for this day. Please choose another time.');
      }
    }

    final appointments = firestore.collection('appointments');
    final slotId = appointment.slotId;
    final createdStatus = policy.autoConfirm ? 'confirmed' : 'pending';

    final created = await firestore.runTransaction((tx) async {
      if (slotId != null) {
        final slotRef = firestore
            .collection('availability')
            .doc(appointment.doctorId)
            .collection('slots')
            .doc(slotId);
        final slotSnap = await tx.get(slotRef);
        if (!slotSnap.exists) {
          throw Exception('Selected slot no longer exists.');
        }
        final slotData = slotSnap.data() as Map<String, dynamic>;
        final isBooked = (slotData['isBooked'] as bool?) ?? false;
        if (isBooked) {
          throw Exception('Selected slot is already booked.');
        }

        tx.update(slotRef, {
          'isBooked': true,
          'bookedBy': appointment.userId,
          'bookedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final docRef = appointments.doc();
      final apptMap = appointment.toMap();
      apptMap['id'] = docRef.id;
      apptMap['status'] = createdStatus;
      apptMap['createdAt'] = FieldValue.serverTimestamp();
      apptMap['updatedAt'] = FieldValue.serverTimestamp();

      tx.set(docRef, apptMap);
      return AppointmentModel.fromMap({
        ...appointment.toMap(),
        'id': docRef.id,
        'status': createdStatus,
      });
    });
    try {
      final createdId = created.id;
      if (createdId != null && createdId.isNotEmpty) {
        await _policyService.onAppointmentCreated(appointmentId: createdId);
      }
    } catch (_) {
      // Non-blocking: booking succeeded even if downstream notification enqueue fails.
    }
    return created;
  }

  Future<int> _countBookingsForDay({
    required String field,
    required String id,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) async {
    final snapshot = await firestore
        .collection('appointments')
        .where(field, isEqualTo: id)
        .where('appointmentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('appointmentTime', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    return snapshot.docs.where((doc) {
      final status = (doc.data()['status'] as String?)?.toLowerCase() ?? 'pending';
      return !_nonBlockingStatuses.contains(status);
    }).length;
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForUser(String userId) async {
    final q = await _col.where('userId', isEqualTo: userId).orderBy('appointmentTime', descending: true).get();
    return q.docs.map((d) {
      final model = d.data();
      return AppointmentModel.fromMap({...model.toMap(), 'id': d.id});
    }).toList();
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDoctor(String doctorId) async {
    final q = await _col.where('doctorId', isEqualTo: doctorId).orderBy('appointmentTime', descending: true).get();
    return q.docs.map((d) {
      final model = d.data();
      return AppointmentModel.fromMap({...model.toMap(), 'id': d.id});
    }).toList();
  }

  @override
  Future<List<AppointmentModel>> getAllAppointments() async {
    final q = await _col.orderBy('appointmentTime', descending: true).get();
    return q.docs.map((d) {
      final model = d.data();
      return AppointmentModel.fromMap({...model.toMap(), 'id': d.id});
    }).toList();
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'statusUpdatedByRole': 'system',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await _policyService.onAppointmentStatusChanged(
        appointmentId: appointmentId,
        newStatus: status,
        actorRole: AppointmentActorRole.system,
      );
    } catch (_) {
      // Keep status update non-blocking for side effects.
    }
  }
}

class _BookingPolicy {
  final bool bookingEnabled;
  final String bookingDisabledMessage;
  final bool autoConfirm;
  final int minNoticeHours;
  final int maxBookingsPerPatientPerDay;
  final int maxBookingsPerDoctorPerDay;

  const _BookingPolicy({
    required this.bookingEnabled,
    required this.bookingDisabledMessage,
    required this.autoConfirm,
    required this.minNoticeHours,
    required this.maxBookingsPerPatientPerDay,
    required this.maxBookingsPerDoctorPerDay,
  });
}
