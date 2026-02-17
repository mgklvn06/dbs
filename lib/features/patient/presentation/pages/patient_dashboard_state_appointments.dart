// ignore_for_file: deprecated_member_use, unused_element_parameter, use_build_context_synchronously, invalid_use_of_protected_member

part of 'patient_dashboard_page.dart';

extension _PatientDashboardPageStateAppointmentsExt
    on _PatientDashboardPageState {
  void _handleBookDoctor(BuildContext context, DoctorEntity doctor) {
    Navigator.pushNamed(context, Routes.bookingAppointment, arguments: doctor);
  }

  int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  bool _readBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  String _normalizeProfileVisibility(dynamic raw) {
    final value = '$raw'.trim().toLowerCase();
    if (value == 'public' || value == 'appointment_only') return value;
    return 'appointment_only';
  }

  String _normalizeReminderLeadTime(dynamic raw) {
    final value = '$raw'.trim().toLowerCase();
    if (value == '1h' || value == '24h') return value;
    return '24h';
  }

  bool _hasProviderLinked(String providerId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (provider) => provider.providerId == providerId,
    );
  }

  bool _canCancelAppointment(
    DateTime dateTime,
    String status,
    int cutoffHours,
  ) {
    if (status != 'pending' && status != 'confirmed' && status != 'accepted') {
      return false;
    }
    final safeCutoffHours = max(0, cutoffHours);
    final cutoff = DateTime.now().add(Duration(hours: safeCutoffHours));
    return dateTime.isAfter(cutoff);
  }

  Future<int> _effectiveCancellationWindowHours({
    required String doctorId,
    required int systemDeadlineHours,
  }) async {
    final safeSystem = max(0, systemDeadlineHours);
    if (doctorId.isEmpty) return safeSystem;

    final doctorSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorId)
        .get();
    final doctorData = doctorSnap.data() ?? <String, dynamic>{};
    final bookingPreferences = _readMap(doctorData['bookingPreferences']);
    final doctorWindow = max(
      0,
      _readInt(bookingPreferences['cancellationWindowHours'], 0),
    );

    if (doctorWindow == 0) return safeSystem;
    return max(safeSystem, doctorWindow);
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    String appointmentId, {
    required int cancellationDeadlineHours,
  }) async {
    final actorId = FirebaseAuth.instance.currentUser?.uid;
    if (actorId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel appointment'),
          content: const Text(
            'Are you sure you want to cancel this appointment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel appointment'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final apptRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId);
      final apptSnap = await apptRef.get();
      if (!apptSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment no longer exists')),
        );
        return;
      }
      final data = apptSnap.data() ?? <String, dynamic>{};
      final ownerPatientId =
          ((data['patientId'] ?? data['userId']) as Object?)?.toString() ?? '';
      if (ownerPatientId.isNotEmpty && ownerPatientId != actorId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This appointment belongs to a different patient account.',
            ),
          ),
        );
        return;
      }
      final status = (data['status'] as String?) ?? 'pending';
      final doctorId = (data['doctorId'] as String?) ?? '';
      final apptDate = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final effectiveDeadlineHours = await _effectiveCancellationWindowHours(
        doctorId: doctorId,
        systemDeadlineHours: cancellationDeadlineHours,
      );
      final canCancel = _canCancelAppointment(
        apptDate,
        status,
        effectiveDeadlineHours,
      );
      if (!canCancel) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cancellation closed. You can cancel only up to ${max(0, effectiveDeadlineHours)} hour(s) before the appointment.',
            ),
          ),
        );
        return;
      }

      await apptRef.update({
        'status': 'cancelled',
        'statusUpdatedByRole': 'patient',
        'statusUpdatedById': actorId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      try {
        await AppointmentPolicyService().onAppointmentStatusChanged(
          appointmentId: appointmentId,
          newStatus: 'cancelled',
          actorRole: AppointmentActorRole.patient,
        );
      } catch (_) {
        // Keep cancellation successful even if side effects are denied by rules.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Permission denied. Check patient account ownership and cancellation deadline policy.'
          : 'Failed to cancel appointment: ${e.message ?? e.code}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }
}
