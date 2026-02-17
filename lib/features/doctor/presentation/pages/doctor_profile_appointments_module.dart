// ignore_for_file: deprecated_member_use

part of 'doctor_profile_page.dart';

class _DoctorAppointmentsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController searchController;
  final String query;
  final String statusFilter;
  final bool doctorBookingEnabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<Map<String, String>> Function(Set<String> ids) fetchNames;
  final Future<void> Function(String appointmentId, String status)
  onUpdateStatus;
  final Future<void> Function(String appointmentId, String? currentNotes)
  onAddNotes;

  const _DoctorAppointmentsModule({
    required this.doctorId,
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.doctorBookingEnabled,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.fetchNames,
    required this.onUpdateStatus,
    required this.onAddNotes,
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
                'Appointments management',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirm, cancel, and complete appointments.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (!doctorBookingEnabled) ...[
                const SizedBox(height: 10),
                Text(
                  'Appointment status actions are currently disabled by admin settings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onQueryChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by patient name',
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
                  .where('doctorId', isEqualTo: doctorId)
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
                  return const Center(child: Text('No appointments found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  if (statusFilter != 'all' && statusFilter != status) continue;
                  final dt = _parseDate(
                    data['appointmentTime'] ?? data['dateTime'],
                  );
                  filtered.add(
                    _AppointmentView(
                      id: doc.id,
                      patientId: (data['userId'] as String?) ?? '',
                      dateTime: dt,
                      status: status,
                      notes: data['notes'] as String?,
                    ),
                  );
                }

                filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchNames(filtered.map((e) => e.patientId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    final visible = filtered.where((appt) {
                      if (normalized.isEmpty) return true;
                      final pname = (names[appt.patientId] ?? appt.patientId)
                          .toLowerCase();
                      return pname.contains(normalized);
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
                        final pname = names[appt.patientId] ?? appt.patientId;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pname,
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
                              if ((appt.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Notes: ${appt.notes}'),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _buildAppointmentActions(appt),
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

  List<Widget> _buildAppointmentActions(_AppointmentView appt) {
    final actions = <Widget>[];

    void addAction(
      String label,
      IconData icon,
      String status, {
      bool enabled = true,
    }) {
      final actionEnabled = doctorBookingEnabled && enabled;
      actions.add(
        OutlinedButton.icon(
          onPressed: actionEnabled
              ? () => onUpdateStatus(appt.id, status)
              : null,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    if (appt.status == 'pending') {
      addAction('Confirm', Icons.check_circle_outline, 'confirmed');
      addAction('Cancel', Icons.cancel_outlined, 'cancelled');
    } else if (appt.status == 'confirmed' || appt.status == 'accepted') {
      final canFinalize = _canFinalizeAppointment(appt.dateTime);
      addAction('Complete', Icons.done_all, 'completed', enabled: canFinalize);
      addAction(
        'No show',
        Icons.person_off_outlined,
        'no_show',
        enabled: canFinalize,
      );
      addAction('Cancel', Icons.cancel_outlined, 'cancelled');
    }

    actions.add(
      OutlinedButton.icon(
        onPressed: doctorBookingEnabled
            ? () => onAddNotes(appt.id, appt.notes)
            : null,
        icon: const Icon(Icons.notes_outlined),
        label: const Text('Notes'),
      ),
    );

    return actions;
  }

  bool _canFinalizeAppointment(DateTime dateTime) {
    final now = DateTime.now();
    return !dateTime.isAfter(now);
  }
}

