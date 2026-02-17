// ignore_for_file: deprecated_member_use

part of 'admin_dashboard.dart';

class _ReportsModule extends StatelessWidget {
  final Future<_AdminReportsData> reportsFuture;
  final VoidCallback onRefresh;

  const _ReportsModule({required this.reportsFuture, required this.onRefresh});

  Future<void> _previewPdf(BuildContext context, _AdminReportsData data) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => _buildAdminReportPdf(data));
    } on MissingPluginException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF plugin not available. Fully stop and re-run the app (not just hot reload).',
          ),
        ),
      );
    } on pw.TooManyPagesException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF content overflowed page limits. Try refreshing and exporting again.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to preview PDF: $e')));
    }
  }

  Future<void> _downloadPdf(
    BuildContext context,
    _AdminReportsData data,
  ) async {
    try {
      final bytes = await _buildAdminReportPdf(data);
      await Printing.sharePdf(bytes: bytes, filename: _buildReportFileName());
    } on MissingPluginException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF plugin not available. Fully stop and re-run the app (not just hot reload).',
          ),
        ),
      );
    } on pw.TooManyPagesException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF content overflowed page limits. Try refreshing and exporting again.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download PDF: $e')));
    }
  }

  Future<void> _reviewModerationEvent(
    BuildContext context, {
    required String eventId,
    required bool approve,
  }) async {
    String? reviewReason;
    if (approve) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Approve moderation action'),
            content: const Text('Apply this moderation action now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Approve'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    } else {
      final reasonController = TextEditingController();
      reviewReason = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Dismiss moderation action'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Provide a reason for dismissal. This will be visible in the moderation record.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Dismissal reason',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(dialogContext, reason);
                },
                child: const Text('Dismiss'),
              ),
            ],
          );
        },
      );
      reasonController.dispose();
      if (reviewReason == null || reviewReason.trim().isEmpty) return;
    }

    try {
      final outcome = await AppointmentPolicyService().reviewModerationEvent(
        eventId: eventId,
        approve: approve,
        reviewedByAdminId: FirebaseAuth.instance.currentUser?.uid,
        reviewReason: reviewReason,
      );
      if (!context.mounted) return;
      final message = switch (outcome) {
        ModerationReviewOutcome.applied => 'Moderation action applied',
        ModerationReviewOutcome.dismissed => 'Moderation action dismissed',
        ModerationReviewOutcome.skipped =>
          'Moderation action skipped (threshold no longer met)',
        ModerationReviewOutcome.notFound => 'Moderation event no longer exists',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      onRefresh();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed moderation review: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminReportsData>(
      future: reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load reports: ${snapshot.error}'),
          );
        }
        final data = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reports & analytics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _previewPdf(context, data),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Preview PDF'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _downloadPdf(context, data),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download PDF'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor deletion requests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Approve or reject doctor account deletion requests. Approval runs blocker checks before applying.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('moderation_events')
                          .where('status', isEqualTo: 'pending_review')
                          .limit(30)
                          .snapshots(),
                      builder: (context, queueSnap) {
                        if (queueSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (queueSnap.hasError) {
                          return const Text('Failed to load deletion requests');
                        }
                        final docs = (queueSnap.data?.docs ?? []).where((doc) {
                          final kind = (doc.data()['kind'] as String?) ?? '';
                          return kind == 'doctor_account_deletion_request';
                        }).toList();
                        if (docs.isEmpty) {
                          return Text(
                            'No pending doctor deletion requests.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final event = doc.data();
                            final targetId =
                                (event['targetId'] as String?) ?? 'unknown';
                            final createdAt = _parseDate(event['createdAt']);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Doctor ID: $targetId',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Requested: ${_formatDateTime(createdAt)}',
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _reviewModerationEvent(
                                          context,
                                          eventId: doc.id,
                                          approve: false,
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject request'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _reviewModerationEvent(
                                          context,
                                          eventId: doc.id,
                                          approve: true,
                                        ),
                                        icon: const Icon(Icons.gavel_outlined),
                                        label: const Text('Approve request'),
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                          title: 'Utilization (30d)',
                          value:
                              '${(data.doctorUtilizationRate * 100).toStringAsFixed(1)}%',
                        ),
                        _MetricCard(
                          title: 'Booked / total slots',
                          value: '${data.bookedSlots} / ${data.totalSlots}',
                        ),
                        _MetricCard(
                          title: 'Pending moderation',
                          value: data.pendingModerationEvents.toString(),
                        ),
                        _MetricCard(
                          title: 'Pending notifications',
                          value: data.pendingNotificationEvents.toString(),
                        ),
                        _MetricCard(
                          title: 'Applied moderation',
                          value: data.appliedModerationEvents.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moderation review queue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('moderation_events')
                          .where('status', isEqualTo: 'pending_review')
                          .limit(20)
                          .snapshots(),
                      builder: (context, queueSnap) {
                        if (queueSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (queueSnap.hasError) {
                          return const Text('Failed to load moderation queue');
                        }
                        final docs = (queueSnap.data?.docs ?? []).where((doc) {
                          final kind = (doc.data()['kind'] as String?) ?? '';
                          return kind != 'doctor_account_deletion_request';
                        }).toList();
                        if (docs.isEmpty) {
                          return Text(
                            'No pending moderation actions.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final event = doc.data();
                            final kind = _moderationKindLabel(
                              (event['kind'] as String?) ?? '',
                            );
                            final targetId =
                                (event['targetId'] as String?) ?? 'unknown';
                            final count =
                                (event['count'] as num?)?.toInt() ?? 0;
                            final threshold =
                                (event['threshold'] as num?)?.toInt() ?? 0;
                            final createdAt = _parseDate(event['createdAt']);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kind,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Target: $targetId'),
                                  Text('Count: $count / Threshold: $threshold'),
                                  Text(
                                    'Created: ${_formatDateTime(createdAt)}',
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _reviewModerationEvent(
                                          context,
                                          eventId: doc.id,
                                          approve: false,
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Dismiss'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _reviewModerationEvent(
                                          context,
                                          eventId: doc.id,
                                          approve: true,
                                        ),
                                        icon: const Icon(Icons.gavel_outlined),
                                        label: const Text('Approve'),
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments per day (7 days)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BarList(points: data.appointmentsPerDay),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 760;
                  final leftCard = AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking status breakdown (30 days)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _PieReportChart(points: data.bookingStatusBreakdown),
                      ],
                    ),
                  );
                  final rightCard = AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most booked doctors',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _RankList(points: data.mostBookedDoctors),
                      ],
                    ),
                  );
                  if (isNarrow) {
                    return Column(
                      children: [
                        leftCard,
                        const SizedBox(height: 12),
                        rightCard,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: leftCard),
                      const SizedBox(width: 12),
                      Expanded(child: rightCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              AppCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancellation rate',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(data.cancellationRate * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Active users (7 days)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.activeUsersWeekly.toString(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancellation rate',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(data.cancellationRate * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active users (7 days)',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data.activeUsersWeekly.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

