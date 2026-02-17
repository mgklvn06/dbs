// ignore_for_file: deprecated_member_use, unused_element_parameter, use_build_context_synchronously, invalid_use_of_protected_member

part of 'patient_dashboard_page.dart';

extension _PatientDashboardPageStateAccountExt on _PatientDashboardPageState {
  Future<void> _promptDeleteAccount(BuildContext rootContext) async {
    if (_isAccountActionRunning) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmController = TextEditingController();
    final shouldDelete = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently removes your sign-in access. Type DELETE to continue.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(labelText: 'Type DELETE'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                confirmController.text.trim().toUpperCase() == 'DELETE',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(rootContext).colorScheme.error,
                foregroundColor: Theme.of(rootContext).colorScheme.onError,
              ),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    confirmController.dispose();

    if (shouldDelete != true) return;

    setState(() => _isAccountActionRunning = true);
    final uid = user.uid;
    try {
      await user.delete();
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {
        // Best effort only. Auth deletion already removed account access.
      }
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        rootContext,
        Routes.landing,
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'requires-recent-login'
          ? 'Please sign in again, then retry account deletion.'
          : e.message ?? 'Failed to delete account.';
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    } finally {
      if (mounted) setState(() => _isAccountActionRunning = false);
    }
  }

  Future<void> _showDoctorDetails(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final name = (data['name'] as String?) ?? 'Doctor';
    final specialty = (data['specialty'] as String?) ?? 'Specialist';
    final bio = (data['bio'] as String?) ?? '';
    final fee = data['consultationFee'];
    final experience = data['experienceYears'];
    final imageUrl = data['profileImageUrl'] as String?;

    final slotsSnap = await FirebaseFirestore.instance
        .collection('availability')
        .doc(doc.id)
        .collection('slots')
        .where('isBooked', isEqualTo: false)
        .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startTime')
        .limit(5)
        .get();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Icon(Icons.medical_services_outlined)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              specialty,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (experience != null)
                              Text('Experience: $experience years'),
                            if (fee != null) Text('Fee: $fee'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(bio),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming availability',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (slotsSnap.docs.isEmpty)
                    const Text('No available slots')
                  else
                    Column(
                      children: slotsSnap.docs.map((slot) {
                        final slotData = slot.data();
                        final start = _parseDate(slotData['startTime']);
                        final end = _parseDate(slotData['endTime']);
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${_formatDateTime(start)} - ${_formatTime(end)}',
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleBookDoctor(
                  context,
                  DoctorEntity(id: doc.id, name: name, specialty: specialty),
                );
              },
              child: const Text('Book now'),
            ),
          ],
        );
      },
    );
  }
}
