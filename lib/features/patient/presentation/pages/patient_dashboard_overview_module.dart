// ignore_for_file: deprecated_member_use

part of 'patient_dashboard_page.dart';

class _PatientDashboardModule extends StatelessWidget {
  final Future<_PatientDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;

  const _PatientDashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
    required this.fetchDoctorNames,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PatientDashboardMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load dashboard: ${snapshot.error}'),
          );
        }
        final data = snapshot.data!;
        final next = data.nextAppointment;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your overview',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            title: 'Upcoming',
                            value: data.upcomingCount.toString(),
                          ),
                          _MetricCard(
                            title: 'Past visits',
                            value: data.pastCount.toString(),
                          ),
                          _MetricCard(
                            title: 'Next appointment',
                            value: next == null
                                ? 'None'
                                : _formatDateTime(next.dateTime),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next appointment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (next == null)
                      const Text('No upcoming appointments')
                    else
                      FutureBuilder<Map<String, String>>(
                        future: fetchDoctorNames({next.doctorId}),
                        builder: (context, nameSnap) {
                          final names = nameSnap.data ?? {};
                          final doctorName =
                              names[next.doctorId] ?? next.doctorId;
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$doctorName - ${_formatDateTime(next.dateTime)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              _StatusPill(
                                label: next.status,
                                active:
                                    next.status == 'confirmed' ||
                                    next.status == 'pending',
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended doctors',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.recommendedDoctors.isEmpty)
                      const Text('No recommendations available')
                    else
                      Column(
                        children: data.recommendedDoctors.map((doc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage:
                                      doc.imageUrl != null &&
                                          doc.imageUrl!.isNotEmpty
                                      ? NetworkImage(doc.imageUrl!)
                                      : null,
                                  child:
                                      doc.imageUrl == null ||
                                          doc.imageUrl!.isEmpty
                                      ? const Icon(
                                          Icons.medical_services_outlined,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        doc.specialty,
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
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

