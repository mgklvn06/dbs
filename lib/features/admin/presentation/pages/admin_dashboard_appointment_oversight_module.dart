// ignore_for_file: deprecated_member_use

part of 'admin_dashboard.dart';

class _AppointmentOversightModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final String? doctorFilterId;
  final DateTimeRange? range;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<DateTimeRange?> onRangeChanged;

  const _AppointmentOversightModule({
    required this.searchController,
    required this.query,
    required this.doctorFilterId,
    required this.range,
    required this.onQueryChanged,
    required this.onDoctorChanged,
    required this.onRangeChanged,
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
                'Appointment oversight',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search, filter, and manage appointments.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by patient or doctor',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DoctorFilter(
                          selectedDoctorId: doctorFilterId,
                          onChanged: onDoctorChanged,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 1),
                                    initialDateRange: range,
                                  );
                                  onRangeChanged(picked);
                                },
                                icon: const Icon(Icons.date_range_outlined),
                                label: Text(
                                  range == null
                                      ? 'Filter by date'
                                      : _formatRange(range!),
                                ),
                              ),
                            ),
                            if (range != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Clear date filter',
                                onPressed: () => onRangeChanged(null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _DoctorFilter(
                          selectedDoctorId: doctorFilterId,
                          onChanged: onDoctorChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                            initialDateRange: range,
                          );
                          onRangeChanged(picked);
                        },
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          range == null
                              ? 'Filter by date'
                              : _formatRange(range!),
                        ),
                      ),
                      if (range != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Clear date filter',
                          onPressed: () => onRangeChanged(null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ],
                  );
                },
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
                  .orderBy('appointmentTime', descending: true)
                  .limit(200)
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

                return FutureBuilder<Map<String, Map<String, String>>>(
                  future: _prefetchNames(docs),
                  builder: (context, nameSnap) {
                    if (nameSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = nameSnap.data?['users'] ?? {};
                    final doctors = nameSnap.data?['doctors'] ?? {};

                    final normalized = query.trim().toLowerCase();
                    final filtered = docs.where((doc) {
                      final data = doc.data();
                      final doctorId = (data['doctorId'] as String?) ?? '';
                      final userId = (data['userId'] as String?) ?? '';
                      final dt = _parseDate(
                        data['appointmentTime'] ?? data['dateTime'],
                      );
                      final matchDoctor =
                          doctorFilterId == null || doctorFilterId == doctorId;
                      final matchRange =
                          range == null ||
                          (dt.isAfter(
                                range!.start.subtract(
                                  const Duration(seconds: 1),
                                ),
                              ) &&
                              dt.isBefore(
                                range!.end.add(const Duration(days: 1)),
                              ));
                      if (!matchDoctor || !matchRange) return false;
                      if (normalized.isEmpty) return true;
                      final userName = (users[userId] ?? userId).toLowerCase();
                      final doctorName = (doctors[doctorId] ?? doctorId)
                          .toLowerCase();
                      return userName.contains(normalized) ||
                          doctorName.contains(normalized) ||
                          userId.contains(normalized) ||
                          doctorId.contains(normalized);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No matching appointments'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data();
                        final userId = (data['userId'] as String?) ?? '';
                        final doctorId = (data['doctorId'] as String?) ?? '';
                        final status = (data['status'] as String?) ?? 'pending';
                        final disputed = (data['disputed'] as bool?) ?? false;
                        final dt = _parseDate(
                          data['appointmentTime'] ?? data['dateTime'],
                        );
                        final patient = users[userId] ?? userId;
                        final doctor = doctors[doctorId] ?? doctorId;

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$patient -> $doctor',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusPill(
                                    label: status,
                                    active:
                                        status == 'confirmed' ||
                                        status == 'accepted' ||
                                        status == 'pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_formatDateTime(dt)} | ${disputed ? 'Disputed' : 'Normal'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _updateAppointmentStatus(
                                      doc.id,
                                      'cancelled',
                                    ),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _toggleDispute(doc.id, !disputed),
                                    icon: Icon(
                                      disputed
                                          ? Icons.flag_outlined
                                          : Icons.flag,
                                    ),
                                    label: Text(
                                      disputed
                                          ? 'Clear dispute'
                                          : 'Mark dispute',
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
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateAppointmentStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({
      'status': status,
      'statusUpdatedByRole': 'admin',
      'statusUpdatedById': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await AppointmentPolicyService().onAppointmentStatusChanged(
        appointmentId: id,
        newStatus: status,
        actorRole: AppointmentActorRole.admin,
      );
    } catch (_) {
      // Keep admin status update successful even if side effects fail.
    }
  }

  Future<void> _toggleDispute(String id, bool disputed) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({
      'disputed': disputed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, Map<String, String>>> _prefetchNames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final userIds = <String>{};
    final doctorIds = <String>{};
    for (var d in docs) {
      final data = d.data();
      userIds.add((data['userId'] as String?) ?? '');
      doctorIds.add((data['doctorId'] as String?) ?? '');
    }

    final users = <String, String>{};
    final doctors = <String, String>{};

    Future<void> fetchUsers() async {
      final ids = userIds.where((e) => e.isNotEmpty).toList();
      const chunk = 10;
      for (var i = 0; i < ids.length; i += chunk) {
        final slice = ids.sublist(i, min(i + chunk, ids.length));
        final q = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (var d in q.docs) {
          final data = d.data();
          users[d.id] =
              (data['displayName'] as String?) ??
              (data['email'] as String?) ??
              d.id;
        }
      }
    }

    Future<void> fetchDoctors() async {
      final ids = doctorIds.where((e) => e.isNotEmpty).toList();
      const chunk = 10;
      for (var i = 0; i < ids.length; i += chunk) {
        final slice = ids.sublist(i, min(i + chunk, ids.length));
        final q = await firestore
            .collection('doctors')
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (var d in q.docs) {
          final data = d.data();
          doctors[d.id] = (data['name'] as String?) ?? d.id;
        }
      }
    }

    await Future.wait([fetchUsers(), fetchDoctors()]);
    return {'users': users, 'doctors': doctors};
  }
}

