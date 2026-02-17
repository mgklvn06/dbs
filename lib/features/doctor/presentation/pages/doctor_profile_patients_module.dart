// ignore_for_file: deprecated_member_use

part of 'doctor_profile_page.dart';

class _DoctorPatientsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<Map<String, _UserDetails>> Function(Set<String> ids)
  fetchUserDetails;
  final Future<void> Function(String patientId, String patientName)
  onViewHistory;

  const _DoctorPatientsModule({
    required this.doctorId,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.fetchUserDetails,
    required this.onViewHistory,
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
                'Patients',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Patients who have booked with you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search patient name',
                  prefixIcon: Icon(Icons.search),
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
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load patients'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No patients yet'));
                }

                final patientMap = <String, _PatientSummary>{};
                for (final doc in docs) {
                  final data = doc.data();
                  final patientId = (data['userId'] as String?) ?? '';
                  if (patientId.isEmpty) continue;
                  final dt = _parseDate(
                    data['appointmentTime'] ?? data['dateTime'],
                  );
                  final summary = patientMap[patientId];
                  if (summary == null) {
                    patientMap[patientId] = _PatientSummary(
                      id: patientId,
                      lastVisit: dt,
                      count: 1,
                    );
                  } else {
                    final last = dt.isAfter(summary.lastVisit)
                        ? dt
                        : summary.lastVisit;
                    patientMap[patientId] = _PatientSummary(
                      id: patientId,
                      lastVisit: last,
                      count: summary.count + 1,
                    );
                  }
                }

                final patientIds = patientMap.keys.toSet();
                return FutureBuilder<Map<String, _UserDetails>>(
                  future: fetchUserDetails(patientIds),
                  builder: (context, snap) {
                    final details = snap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final list = patientMap.values.where((p) {
                      if (normalized.isEmpty) return true;
                      final name = (details[p.id]?.name ?? p.id).toLowerCase();
                      return name.contains(normalized);
                    }).toList();

                    if (list.isEmpty) {
                      return const Center(child: Text('No matching patients'));
                    }

                    list.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final info = details[item.id];
                        final name = info?.name ?? item.id;
                        final email = info?.email ?? '';
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(child: Icon(Icons.person)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (email.isNotEmpty)
                                          Text(
                                            email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _StatusPill(
                                    label: '${item.count} visits',
                                    active: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Last visit: ${_formatDateTime(item.lastVisit)}',
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => onViewHistory(item.id, name),
                                icon: const Icon(Icons.history),
                                label: const Text('History'),
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

