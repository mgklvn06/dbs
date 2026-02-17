// ignore_for_file: deprecated_member_use

part of 'patient_dashboard_page.dart';

class _MedicalHistoryModule extends StatelessWidget {
  final String userId;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;

  const _MedicalHistoryModule({
    required this.userId,
    required this.fetchDoctorNames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical history',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed appointments and shared notes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load medical history'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No completed appointments yet'),
                  );
                }

                final completed = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  final dt = _parseDate(
                    data['appointmentTime'] ?? data['dateTime'],
                  );
                  if (status != 'completed' || !dt.isBefore(DateTime.now())) {
                    continue;
                  }
                  completed.add(
                    _AppointmentView(
                      id: doc.id,
                      doctorId: (data['doctorId'] as String?) ?? '',
                      dateTime: dt,
                      status: status,
                      notes: data['notes'] as String?,
                    ),
                  );
                }

                if (completed.isEmpty) {
                  return const Center(
                    child: Text('No completed appointments yet'),
                  );
                }

                completed.sort((a, b) => b.dateTime.compareTo(a.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchDoctorNames(
                    completed.map((e) => e.doctorId).toSet(),
                  ),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    return ListView.separated(
                      itemCount: completed.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = completed[index];
                        final dname = names[appt.doctorId] ?? appt.doctorId;
                        final notes = appt.notes?.trim() ?? '';

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dname,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusPill(label: 'completed', active: true),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatDateTime(appt.dateTime)),
                              const SizedBox(height: 8),
                              Text(
                                notes.isEmpty
                                    ? 'Notes: No notes shared yet.'
                                    : 'Notes: $notes',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

