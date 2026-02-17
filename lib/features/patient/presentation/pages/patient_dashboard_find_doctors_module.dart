// ignore_for_file: deprecated_member_use

part of 'patient_dashboard_page.dart';

class _FindDoctorsModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final String specialtyFilter;
  final bool onlyAvailable;
  final Set<String> preferredDoctorIds;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  final Future<void> Function(String doctorId, bool preferred)
  onTogglePreferredDoctor;
  final void Function(DoctorEntity doctor) onBookDoctor;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
  onViewDoctor;

  const _FindDoctorsModule({
    required this.searchController,
    required this.query,
    required this.specialtyFilter,
    required this.onlyAvailable,
    required this.preferredDoctorIds,
    required this.onQueryChanged,
    required this.onSpecialtyChanged,
    required this.onAvailabilityChanged,
    required this.onTogglePreferredDoctor,
    required this.onBookDoctor,
    required this.onViewDoctor,
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
                'Find doctors',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Search by specialty and availability.',
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
                  hintText: 'Search by name or specialty',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SpecialtyFilter(
                      selected: specialtyFilter,
                      onChanged: onSpecialtyChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Switch(
                        value: onlyAvailable,
                        onChanged: onAvailabilityChanged,
                      ),
                      const Text('Available now'),
                    ],
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
                  .collection('doctors')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load doctors'));
                }
                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  return _isDoctorDiscoverable(doc.data());
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('No doctors available'));
                }

                return FutureBuilder<Map<String, bool>>(
                  future: _prefetchAvailabilityStatus(docs),
                  builder: (context, availabilitySnap) {
                    final availability = availabilitySnap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final filtered = docs.where((doc) {
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? '';
                      final specialty = (data['specialty'] as String?) ?? '';
                      if (specialtyFilter != 'All' &&
                          specialty != specialtyFilter) {
                        return false;
                      }
                      if (onlyAvailable && availability[doc.id] != true) {
                        return false;
                      }
                      if (normalized.isEmpty) return true;
                      return name.toLowerCase().contains(normalized) ||
                          specialty.toLowerCase().contains(normalized);
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
                            (data['specialty'] as String?) ?? 'Specialist';
                        final imageUrl = data['profileImageUrl'] as String?;
                        final available = availability[doc.id] == true;
                        final preferred = preferredDoctorIds.contains(doc.id);

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage:
                                        imageUrl != null && imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null || imageUrl.isEmpty
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
                                          name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          specialty,
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
                                  IconButton(
                                    tooltip: preferred
                                        ? 'Remove preferred doctor'
                                        : 'Save preferred doctor',
                                    onPressed: () => onTogglePreferredDoctor(
                                      doc.id,
                                      !preferred,
                                    ),
                                    icon: Icon(
                                      preferred
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: preferred
                                          ? Colors.amber.shade700
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                    ),
                                  ),
                                  _StatusPill(
                                    label: available ? 'Available' : 'No slots',
                                    active: available,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => onViewDoctor(doc),
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View profile'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => onBookDoctor(
                                      DoctorEntity(
                                        id: doc.id,
                                        name: name,
                                        specialty: specialty,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    label: const Text('Book now'),
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

  Future<Map<String, bool>> _prefetchAvailabilityStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final result = <String, bool>{};
    final db = FirebaseFirestore.instance;
    final now = Timestamp.fromDate(DateTime.now());
    for (final doc in docs) {
      final slots = await db
          .collection('availability')
          .doc(doc.id)
          .collection('slots')
          .where('isBooked', isEqualTo: false)
          .where('startTime', isGreaterThan: now)
          .limit(1)
          .get();
      result[doc.id] = slots.docs.isNotEmpty;
    }
    return result;
  }

  bool _isDoctorDiscoverable(Map<String, dynamic> data) {
    final profileVisible = _readBool(data['profileVisible'], true);
    final acceptingBookings = _readBool(data['acceptingBookings'], true);
    return profileVisible && acceptingBookings;
  }

  bool _readBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }
}

