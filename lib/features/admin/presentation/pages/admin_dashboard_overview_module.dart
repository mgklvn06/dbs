part of 'admin_dashboard.dart';

class _DashboardModule extends StatelessWidget {
  final Future<_AdminDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;

  const _DashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminDashboardMetrics>(
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
                delay: const Duration(milliseconds: 50),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'System snapshot',
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
                            title: 'Total users',
                            value: data.totalUsers.toString(),
                          ),
                          _MetricCard(
                            title: 'Total doctors',
                            value: data.totalDoctors.toString(),
                          ),
                          _MetricCard(
                            title: 'Appointments today',
                            value: data.appointmentsToday.toString(),
                          ),
                          _MetricCard(
                            title: 'Active appointments',
                            value: data.activeAppointments.toString(),
                          ),
                          _MetricCard(
                            title: 'Completed appointments',
                            value: data.completedAppointments.toString(),
                          ),
                          _MetricCard(
                            title: 'Pending approvals',
                            value: data.pendingApprovals.toString(),
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
                      'Quick actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _ActionChip(
                          label: 'Approve doctors',
                          icon: Icons.verified_user_outlined,
                        ),
                        _ActionChip(
                          label: 'Review appointments',
                          icon: Icons.event_available_outlined,
                        ),
                        _ActionChip(
                          label: 'Audit users',
                          icon: Icons.people_alt_outlined,
                        ),
                      ],
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

