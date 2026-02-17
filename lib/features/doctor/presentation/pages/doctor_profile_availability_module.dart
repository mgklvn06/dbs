// ignore_for_file: deprecated_member_use

part of 'doctor_profile_page.dart';

class _DoctorAvailabilityModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController slotDurationController;
  final TextEditingController breakStartController;
  final TextEditingController breakEndController;
  final TextEditingController blockedDatesController;
  final Set<int> workingDays;
  final bool isGenerating;
  final VoidCallback onSaveSettings;
  final VoidCallback onGenerateSlots;
  final VoidCallback onBlockTime;
  final ValueChanged<int> onToggleDay;
  final void Function(Map<String, dynamic>? data) onLoadSettings;
  final bool availabilityLoaded;
  final ValueChanged<bool> setAvailabilityLoaded;

  const _DoctorAvailabilityModule({
    required this.doctorId,
    required this.startController,
    required this.endController,
    required this.slotDurationController,
    required this.breakStartController,
    required this.breakEndController,
    required this.blockedDatesController,
    required this.workingDays,
    required this.isGenerating,
    required this.onSaveSettings,
    required this.onGenerateSlots,
    required this.onBlockTime,
    required this.onToggleDay,
    required this.onLoadSettings,
    required this.availabilityLoaded,
    required this.setAvailabilityLoaded,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('doctors')
              .doc(doctorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && !availabilityLoaded) {
              onLoadSettings(snapshot.data?.data());
              setAvailabilityLoaded(true);
            }
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Define working hours, slot length, and break times.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Working days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(labels.length, (index) {
                      final day = index + 1;
                      final selected = workingDays.contains(day);
                      return ChoiceChip(
                        label: Text(labels[index]),
                        selected: selected,
                        onSelected: (_) => onToggleDay(day),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                            labelText: 'Start time (HH:MM)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                            labelText: 'End time (HH:MM)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: slotDurationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Slot duration (minutes)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: breakStartController,
                          decoration: const InputDecoration(
                            labelText: 'Break start (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: breakEndController,
                          decoration: const InputDecoration(
                            labelText: 'Break end (optional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: blockedDatesController,
                    decoration: const InputDecoration(
                      labelText: 'Blocked dates (YYYY-MM-DD, comma separated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onSaveSettings,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save settings'),
                      ),
                      OutlinedButton.icon(
                        onPressed: isGenerating ? null : onGenerateSlots,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          isGenerating
                              ? 'Generating...'
                              : 'Generate next 14 days',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onBlockTime,
                        icon: const Icon(Icons.block),
                        label: const Text('Block time'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('availability')
                  .doc(doctorId)
                  .collection('slots')
                  .orderBy('startTime')
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load availability'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No upcoming slots'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final start = _parseDate(data['startTime']);
                    final end = _parseDate(data['endTime']);
                    final isBooked = (data['isBooked'] as bool?) ?? false;
                    final blocked = (data['blockedReason'] as String?) != null;
                    final label = blocked
                        ? 'Blocked'
                        : (isBooked ? 'Booked' : 'Available');

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_formatDateTime(start)} - ${_formatTime(end)}',
                            ),
                          ),
                          _StatusPill(label: label, active: !isBooked),
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

