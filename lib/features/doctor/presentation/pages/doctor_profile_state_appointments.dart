// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, invalid_use_of_protected_member

part of 'doctor_profile_page.dart';

extension _DoctorProfilePageStateAppointmentsExt on _DoctorProfilePageState {
  Future<void> _updateAppointmentStatus(
    BuildContext context,
    String appointmentId,
    String status,
  ) async {
    try {
      final actorId = FirebaseAuth.instance.currentUser?.uid;
      if (actorId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
        return;
      }

      final policy = await _loadDoctorBookingActionPolicy();
      if (!policy.doctorBookingEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Doctor appointment actions are disabled by admin settings.',
            ),
          ),
        );
        return;
      }

      final apptRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId);
      final apptSnap = await apptRef.get();
      if (!apptSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment no longer exists.')),
        );
        return;
      }

      final appt = apptSnap.data() ?? <String, dynamic>{};
      final ownerDoctorId =
          ((appt['doctorUid'] ?? appt['doctorId']) as Object?)?.toString() ??
          '';
      if (ownerDoctorId.isNotEmpty && ownerDoctorId != actorId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This appointment belongs to a different doctor account.',
            ),
          ),
        );
        return;
      }
      final apptDate = _parseDate(appt['appointmentTime'] ?? appt['dateTime']);
      if ((status == 'completed' || status == 'no_show') &&
          apptDate.isAfter(DateTime.now())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You can only mark completed/no-show after appointment time.',
            ),
          ),
        );
        return;
      }

      await apptRef.update({
        'status': status,
        'statusUpdatedByRole': 'doctor',
        'statusUpdatedById': actorId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      try {
        await AppointmentPolicyService().onAppointmentStatusChanged(
          appointmentId: appointmentId,
          newStatus: status,
          actorRole: AppointmentActorRole.doctor,
        );
      } catch (_) {
        // Keep appointment status update non-blocking if side effects are denied by rules.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Appointment updated: $status')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Permission denied. Check doctor account ownership for this appointment and admin booking-action settings.'
          : 'Failed to update appointment: ${e.message ?? e.code}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Future<void> _promptAppointmentNotes(
    BuildContext context,
    String appointmentId,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Appointment notes'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add notes for this appointment',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'notes': result, 'updatedAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save notes: $e')));
    }
  }

  Future<void> _showUserAppointmentHistory(
    BuildContext context,
    String doctorId,
    String userId,
    String userName,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('userId', isEqualTo: userId)
        .get();
    final docs = snap.docs.toList();
    docs.sort((a, b) {
      final adt = _parseDate(
        a.data()['appointmentTime'] ?? a.data()['dateTime'],
      );
      final bdt = _parseDate(
        b.data()['appointmentTime'] ?? b.data()['dateTime'],
      );
      return bdt.compareTo(adt);
    });

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('History: $userName'),
          content: SizedBox(
            width: 440,
            child: docs.isEmpty
                ? const Text('No appointments found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final dt = _parseDate(
                        data['appointmentTime'] ?? data['dateTime'],
                      );
                      final status = (data['status'] as String?) ?? 'pending';
                      return ListTile(
                        dense: true,
                        title: Text(_formatDateTime(dt)),
                        subtitle: Text('Status: $status'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: docs.length,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
