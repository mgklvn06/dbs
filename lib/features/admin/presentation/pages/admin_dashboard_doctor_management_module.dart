// ignore_for_file: deprecated_member_use

part of 'admin_dashboard.dart';

class _DoctorManagementModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(String doctorId, bool active) onApprove;
  final Future<void> Function(String doctorId, bool active) onSuspend;
  final Future<void> Function(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  )
  onEdit;
  final Future<void> Function(
    BuildContext context,
    String doctorId,
    String doctorName,
  )
  onViewAvailability;
  final Future<void> Function(
    BuildContext context,
    String doctorId,
    String doctorName,
  )
  onViewAppointments;

  const _DoctorManagementModule({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onApprove,
    required this.onSuspend,
    required this.onEdit,
    required this.onViewAvailability,
    required this.onViewAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctor management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Approve, suspend, and review doctor activity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or specialty',
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
                  .collection('doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load doctors'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No doctors found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = normalized.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final name = (data['name'] as String?) ?? '';
                        final spec = (data['specialty'] as String?) ?? '';
                        return name.toLowerCase().contains(normalized) ||
                            spec.toLowerCase().contains(normalized);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching doctors'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final name = (data['name'] as String?) ?? 'Doctor';
                    final specialty =
                        (data['specialty'] as String?) ?? 'General';
                    final email = (data['email'] as String?) ?? 'no-email';
                    final isActive = (data['isActive'] as bool?) ?? false;

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      '$specialty | $email',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(
                                label: isActive ? 'Active' : 'Pending',
                                active: isActive,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (!isActive)
                                OutlinedButton.icon(
                                  onPressed: () => onApprove(doc.id, true),
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text('Approve'),
                                ),
                              if (isActive)
                                OutlinedButton.icon(
                                  onPressed: () => onSuspend(doc.id, false),
                                  icon: const Icon(Icons.pause_circle_outline),
                                  label: const Text('Suspend'),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => onEdit(context, doc),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit profile'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    onViewAvailability(context, doc.id, name),
                                icon: const Icon(Icons.schedule_outlined),
                                label: const Text('Availability'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    onViewAppointments(context, doc.id, name),
                                icon: const Icon(
                                  Icons.event_available_outlined,
                                ),
                                label: const Text('Appointments'),
                              ),
                            ],
                          ),
                        ],
                      ),
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

