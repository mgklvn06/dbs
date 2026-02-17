// ignore_for_file: deprecated_member_use

part of 'patient_dashboard_page.dart';

class _PatientAppointmentsModule extends StatelessWidget {
  final String userId;
  final TextEditingController searchController;
  final String query;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;
  final Future<void> Function(String appointmentId) onCancel;
  final bool Function(DateTime dateTime, String status) canCancel;

  const _PatientAppointmentsModule({
    required this.userId,
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.fetchDoctorNames,
    required this.onCancel,
    required this.canCancel,
  });

  @override
  Widget build(BuildContext context) {
    const statusOptions = [
      'all',
      'pending',
      'confirmed',
      'completed',
      'cancelled',
      'no_show',
      'accepted',
      'rejected',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My appointments',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Track and manage your bookings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onQueryChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by doctor',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: statusOptions
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => onStatusChanged(value ?? 'all'),
                    ),
                  ),
                ],
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
                    child: Text('Failed to load appointments'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No appointments yet'));
                }

                final list = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  if (statusFilter != 'all' && statusFilter != status) continue;
                  final dt = _parseDate(
                    data['appointmentTime'] ?? data['dateTime'],
                  );
                  list.add(
                    _AppointmentView(
                      id: doc.id,
                      doctorId: (data['doctorId'] as String?) ?? '',
                      dateTime: dt,
                      status: status,
                    ),
                  );
                }

                list.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchDoctorNames(list.map((e) => e.doctorId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final visible = list.where((appt) {
                      if (normalized.isEmpty) return true;
                      final dname = (names[appt.doctorId] ?? appt.doctorId)
                          .toLowerCase();
                      return dname.contains(normalized);
                    }).toList();

                    if (visible.isEmpty) {
                      return const Center(
                        child: Text('No matching appointments'),
                      );
                    }

                    return ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = visible[index];
                        final dname = names[appt.doctorId] ?? appt.doctorId;
                        final allowCancel = canCancel(
                          appt.dateTime,
                          appt.status,
                        );

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
                                  _StatusPill(
                                    label: appt.status,
                                    active:
                                        appt.status == 'confirmed' ||
                                        appt.status == 'pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatDateTime(appt.dateTime)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: allowCancel
                                        ? () => onCancel(appt.id)
                                        : null,
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
                                  ),
                                ],
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

