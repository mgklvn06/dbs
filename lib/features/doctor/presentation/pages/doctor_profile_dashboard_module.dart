part of 'doctor_profile_page.dart';

class _DoctorDashboardModule extends StatelessWidget {
  final Future<_DoctorDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;
  final Future<Map<String, String>> Function(Set<String> ids) fetchNames;

  const _DoctorDashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
    required this.fetchNames,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DoctorDashboardMetrics>(
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
                              'Today overview',
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
                            title: 'Appointments today',
                            value: data.appointmentsToday.toString(),
                          ),
                          _MetricCard(
                            title: 'Upcoming this week',
                            value: data.upcomingWeek.toString(),
                          ),
                          _MetricCard(
                            title: 'Pending approvals',
                            value: data.pendingApprovals.toString(),
                          ),
                          _MetricCard(
                            title: 'Availability',
                            value: data.availabilityActive
                                ? 'Active'
                                : 'Inactive',
                            accent: data.availabilityActive
                                ? Colors.green
                                : Colors.orange,
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
                      'Next appointments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.nextAppointments.isEmpty)
                      const Text('No upcoming appointments')
                    else
                      FutureBuilder<Map<String, String>>(
                        future: fetchNames(
                          data.nextAppointments.map((e) => e.patientId).toSet(),
                        ),
                        builder: (context, nameSnap) {
                          final names = nameSnap.data ?? {};
                          return Column(
                            children: data.nextAppointments.map((appt) {
                              final pname =
                                  names[appt.patientId] ?? appt.patientId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pname,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(_formatDateTime(appt.dateTime)),
                                    const SizedBox(width: 12),
                                    _StatusPill(
                                      label: appt.status,
                                      active:
                                          appt.status == 'confirmed' ||
                                          appt.status == 'pending',
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
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

