import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dbs/core/settings/system_settings_policy.dart';

enum AppointmentActorRole { patient, doctor, admin, system }

enum ModerationReviewOutcome {
  applied,
  dismissed,
  skipped,
  notFound,
}

class AppointmentPolicyService {
  final FirebaseFirestore firestore;

  AppointmentPolicyService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> onAppointmentCreated({
    required String appointmentId,
  }) async {
    final policy = await SystemSettingsPolicy.load(firestore);
    if (!policy.emailNotificationsEnabled) return;

    final apptSnap = await firestore.collection('appointments').doc(appointmentId).get();
    if (!apptSnap.exists) return;
    final appt = apptSnap.data() ?? <String, dynamic>{};

    await _queueNotificationEvent(
      type: 'booking_created',
      appointmentId: appointmentId,
      appointment: appt,
      metadata: <String, dynamic>{
        'status': (appt['status'] as String?) ?? 'pending',
      },
    );
  }

  Future<void> onAppointmentStatusChanged({
    required String appointmentId,
    required String newStatus,
    required AppointmentActorRole actorRole,
  }) async {
    final policy = await SystemSettingsPolicy.load(firestore);
    final apptSnap = await firestore.collection('appointments').doc(appointmentId).get();
    if (!apptSnap.exists) return;
    final appt = apptSnap.data() ?? <String, dynamic>{};

    await _handleModeration(
      policy: policy,
      appointment: appt,
      newStatus: newStatus,
      actorRole: actorRole,
    );
    await _handleNotification(
      policy: policy,
      appointmentId: appointmentId,
      appointment: appt,
      newStatus: newStatus,
      actorRole: actorRole,
    );
  }

  Future<int> processPendingModerationEvents({int limit = 50}) async {
    final policy = await SystemSettingsPolicy.load(firestore);
    final eventsSnap = await firestore
        .collection('moderation_events')
        .where('status', isEqualTo: 'approved')
        .limit(limit)
        .get();

    var applied = 0;
    for (final doc in eventsSnap.docs) {
      final data = doc.data();
      final appliedToTarget = await _applyModerationEventData(policy: policy, eventData: data);

      await doc.reference.set({
        'status': appliedToTarget ? 'applied' : 'skipped',
        'processedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (appliedToTarget) applied += 1;
    }
    return applied;
  }

  Future<ModerationReviewOutcome> reviewModerationEvent({
    required String eventId,
    required bool approve,
    String? reviewedByAdminId,
  }) async {
    final eventRef = firestore.collection('moderation_events').doc(eventId);
    final eventSnap = await eventRef.get();
    if (!eventSnap.exists) return ModerationReviewOutcome.notFound;

    if (!approve) {
      await eventRef.set({
        'status': 'dismissed',
        'reviewDecision': 'dismiss',
        'reviewedByAdminId': reviewedByAdminId,
        'processedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return ModerationReviewOutcome.dismissed;
    }

    final policy = await SystemSettingsPolicy.load(firestore);
    final applied = await _applyModerationEventData(
      policy: policy,
      eventData: eventSnap.data() ?? <String, dynamic>{},
    );
    await eventRef.set({
      'status': applied ? 'applied' : 'skipped',
      'reviewDecision': 'approve',
      'reviewedByAdminId': reviewedByAdminId,
      'processedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return applied ? ModerationReviewOutcome.applied : ModerationReviewOutcome.skipped;
  }

  Future<void> _handleModeration({
    required SystemSettingsPolicy policy,
    required Map<String, dynamic> appointment,
    required String newStatus,
    required AppointmentActorRole actorRole,
  }) async {
    final normalizedStatus = newStatus.trim().toLowerCase();
    final isDoctorActor = actorRole == AppointmentActorRole.doctor;
    final isAdminActor = actorRole == AppointmentActorRole.admin;
    if (!isDoctorActor && !isAdminActor) return;

    final patientId = (appointment['userId'] as String?) ?? '';
    final doctorId = (appointment['doctorId'] as String?) ?? '';

    if (normalizedStatus == 'no_show' &&
        policy.autoSuspendAfterPatientNoShows > 0 &&
        patientId.isNotEmpty) {
      final noShows = await _countAppointments(
        field: 'userId',
        id: patientId,
        status: 'no_show',
      );
      if (noShows >= policy.autoSuspendAfterPatientNoShows) {
        if (isAdminActor) {
          await _suspendPatient(patientId, noShows, policy.autoSuspendAfterPatientNoShows);
        } else {
          await _queueModerationEvent(
            kind: 'patient_no_show_threshold_reached',
            targetId: patientId,
            doctorId: doctorId,
            threshold: policy.autoSuspendAfterPatientNoShows,
            count: noShows,
          );
        }
      }
    }

    if (normalizedStatus == 'cancelled' &&
        policy.autoSuspendAfterDoctorCancellations > 0 &&
        doctorId.isNotEmpty) {
      final cancellations = await _countAppointments(
        field: 'doctorId',
        id: doctorId,
        status: 'cancelled',
        updatedByRole: 'doctor',
      );
      if (cancellations >= policy.autoSuspendAfterDoctorCancellations) {
        if (isAdminActor) {
          await _suspendDoctor(doctorId, cancellations, policy.autoSuspendAfterDoctorCancellations);
        } else {
          await _queueModerationEvent(
            kind: 'doctor_cancellation_threshold_reached',
            targetId: doctorId,
            doctorId: doctorId,
            threshold: policy.autoSuspendAfterDoctorCancellations,
            count: cancellations,
          );
        }
      }
    }
  }

  Future<void> _handleNotification({
    required SystemSettingsPolicy policy,
    required String appointmentId,
    required Map<String, dynamic> appointment,
    required String newStatus,
    required AppointmentActorRole actorRole,
  }) async {
    if (!policy.emailNotificationsEnabled) return;

    final normalizedStatus = newStatus.trim().toLowerCase();
    if (normalizedStatus == 'cancelled' && !policy.cancellationNotificationsEnabled) {
      return;
    }

    if (normalizedStatus == 'confirmed' && !policy.doctorReminderEnabled) {
      return;
    }

    if (normalizedStatus == 'completed' && !policy.patientReminderEnabled) {
      return;
    }

    if (normalizedStatus != 'cancelled' &&
        normalizedStatus != 'confirmed' &&
        normalizedStatus != 'completed' &&
        !policy.systemAlertsEnabled) {
      return;
    }

    await _queueNotificationEvent(
      type: 'appointment_status_changed',
      appointmentId: appointmentId,
      appointment: appointment,
      metadata: <String, dynamic>{
        'newStatus': normalizedStatus,
        'actorRole': _actorRoleValue(actorRole),
      },
    );
  }

  Future<void> _queueNotificationEvent({
    required String type,
    required String appointmentId,
    required Map<String, dynamic> appointment,
    required Map<String, dynamic> metadata,
  }) async {
    final patientId = (appointment['userId'] as String?) ?? '';
    final doctorId = (appointment['doctorId'] as String?) ?? '';
    await firestore.collection('notification_events').add({
      'type': type,
      'appointmentId': appointmentId,
      'userId': patientId,
      'doctorId': doctorId,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> _queueModerationEvent({
    required String kind,
    required String targetId,
    required String doctorId,
    required int threshold,
    required int count,
  }) async {
    await firestore.collection('moderation_events').add({
      'kind': kind,
      'targetId': targetId,
      'doctorId': doctorId,
      'threshold': threshold,
      'count': count,
      'status': 'pending_review',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _countAppointments({
    required String field,
    required String id,
    required String status,
    String? updatedByRole,
  }) async {
    var query = firestore
        .collection('appointments')
        .where(field, isEqualTo: id)
        .where('status', isEqualTo: status);
    if (updatedByRole != null && updatedByRole.isNotEmpty) {
      query = query.where('statusUpdatedByRole', isEqualTo: updatedByRole);
    }
    final snap = await query.get();
    return snap.docs.length;
  }

  Future<bool> _applyModerationEventData({
    required SystemSettingsPolicy policy,
    required Map<String, dynamic> eventData,
  }) async {
    final kind = (eventData['kind'] as String?) ?? '';
    final targetId = (eventData['targetId'] as String?) ?? '';
    final eventThreshold = _readInt(eventData['threshold'], 0);

    if (kind == 'patient_no_show_threshold_reached' &&
        targetId.isNotEmpty &&
        policy.autoSuspendAfterPatientNoShows > 0) {
      final count = await _countAppointments(
        field: 'userId',
        id: targetId,
        status: 'no_show',
      );
      final threshold = eventThreshold > 0 ? eventThreshold : policy.autoSuspendAfterPatientNoShows;
      if (count >= threshold) {
        await _suspendPatient(targetId, count, threshold);
        return true;
      }
      return false;
    }

    if (kind == 'doctor_cancellation_threshold_reached' &&
        targetId.isNotEmpty &&
        policy.autoSuspendAfterDoctorCancellations > 0) {
      final count = await _countAppointments(
        field: 'doctorId',
        id: targetId,
        status: 'cancelled',
        updatedByRole: 'doctor',
      );
      final threshold = eventThreshold > 0 ? eventThreshold : policy.autoSuspendAfterDoctorCancellations;
      if (count >= threshold) {
        await _suspendDoctor(targetId, count, threshold);
        return true;
      }
      return false;
    }

    return false;
  }

  int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  Future<void> _suspendPatient(String userId, int count, int threshold) async {
    final now = FieldValue.serverTimestamp();
    await firestore.collection('users').doc(userId).set({
      'status': 'suspended',
      'suspendedReason': 'Auto-suspended after $count no-shows (threshold: $threshold).',
      'suspendedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> _suspendDoctor(String doctorId, int count, int threshold) async {
    final now = FieldValue.serverTimestamp();
    await firestore.collection('doctors').doc(doctorId).set({
      'isActive': false,
      'status': 'suspended',
      'suspendedReason': 'Auto-suspended after $count cancellations (threshold: $threshold).',
      'suspendedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await firestore.collection('users').doc(doctorId).set({
      'status': 'suspended',
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  String _actorRoleValue(AppointmentActorRole role) {
    switch (role) {
      case AppointmentActorRole.patient:
        return 'patient';
      case AppointmentActorRole.doctor:
        return 'doctor';
      case AppointmentActorRole.admin:
        return 'admin';
      case AppointmentActorRole.system:
        return 'system';
    }
  }
}
