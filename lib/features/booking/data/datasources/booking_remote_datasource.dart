import 'package:cloud_firestore/cloud_firestore.dart';
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

  BookingRemoteDataSourceImpl({FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

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
    final slotId = appointment.slotId;
    if (slotId == null) {
      final docRef = await _col.add(appointment);
      await docRef.update({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'id': docRef.id,
      });
      final snap = await docRef.get();
      final model = snap.data()!;
      // Ensure id is stored
      final m = AppointmentModel.fromMap({...model.toMap(), 'id': docRef.id});
      await docRef.set(m);
      return m;
    }

    final appointments = firestore.collection('appointments');
    final slotRef = firestore.collection('availability').doc(appointment.doctorId).collection('slots').doc(slotId);

    return firestore.runTransaction((tx) async {
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

      final docRef = appointments.doc();
      final apptMap = appointment.toMap();
      apptMap['id'] = docRef.id;
      apptMap['createdAt'] = FieldValue.serverTimestamp();
      apptMap['updatedAt'] = FieldValue.serverTimestamp();

      tx.set(docRef, apptMap);
      return AppointmentModel.fromMap({...appointment.toMap(), 'id': docRef.id});
    });
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
