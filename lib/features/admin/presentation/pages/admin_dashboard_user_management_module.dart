// ignore_for_file: deprecated_member_use

part of 'admin_dashboard.dart';

class _UserManagementModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String role,
  )
  onSetRole;
  final Future<void> Function(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  )
  onSetStatus;
  final Future<void> Function(BuildContext context, String userId, String label)
  onViewHistory;

  const _UserManagementModule({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onSetRole,
    required this.onSetStatus,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review users, suspend access, and update roles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or email',
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
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load users'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = normalized.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final name = (data['displayName'] as String?) ?? '';
                        final email = (data['email'] as String?) ?? '';
                        return name.toLowerCase().contains(normalized) ||
                            email.toLowerCase().contains(normalized);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching users'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final name = (data['displayName'] as String?) ?? 'Unknown';
                    final email = (data['email'] as String?) ?? 'no-email';
                    final role = (data['role'] as String?) ?? 'user';
                    final status = (data['status'] as String?) ?? 'active';
                    final isSelf = doc.id == currentUser?.uid;

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
                                      '$email | $role | $status${isSelf ? ' (you)' : ''}',
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
                                label: status,
                                active: status == 'active',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    onViewHistory(context, doc.id, name),
                                icon: const Icon(Icons.history),
                                label: const Text('History'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSelf
                                    ? null
                                    : () => _showRoleSheet(
                                        context,
                                        doc,
                                        role,
                                        onSetRole,
                                      ),
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text('Change role'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSelf
                                    ? null
                                    : () => onSetStatus(
                                        context,
                                        doc,
                                        status == 'active'
                                            ? 'suspended'
                                            : 'active',
                                      ),
                                icon: const Icon(Icons.pause_circle_outline),
                                label: Text(
                                  status == 'active' ? 'Suspend' : 'Activate',
                                ),
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

  void _showRoleSheet(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String role,
    Future<void> Function(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      String role,
    )
    onSetRole,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text((doc.data()['displayName'] as String?) ?? doc.id),
                subtitle: Text('Current role: $role'),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: role != 'user',
                leading: const Icon(Icons.person_outline),
                title: const Text('Set role: user'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'user');
                },
              ),
              ListTile(
                enabled: role != 'doctor',
                leading: const Icon(Icons.medical_services_outlined),
                title: const Text('Set role: doctor'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'doctor');
                },
              ),
              ListTile(
                enabled: role != 'admin',
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Set role: admin'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'admin');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

