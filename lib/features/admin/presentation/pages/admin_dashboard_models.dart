part of 'admin_dashboard.dart';

class _AdminDashboardMetrics {
  final int totalUsers;
  final int totalDoctors;
  final int appointmentsToday;
  final int completedAppointments;
  final int activeAppointments;
  final int pendingApprovals;

  const _AdminDashboardMetrics({
    required this.totalUsers,
    required this.totalDoctors,
    required this.appointmentsToday,
    required this.completedAppointments,
    required this.activeAppointments,
    required this.pendingApprovals,
  });
}

class _AdminReportsData {
  final List<_ReportPoint> appointmentsPerDay;
  final List<_ReportPoint> mostBookedDoctors;
  final List<_ReportPoint> bookingStatusBreakdown;
  final int appointmentsToday;
  final int bookedSlots;
  final int totalSlots;
  final double doctorUtilizationRate;
  final double cancellationRate;
  final int activeUsersWeekly;
  final int pendingNotificationEvents;
  final int pendingModerationEvents;
  final int appliedModerationEvents;

  const _AdminReportsData({
    required this.appointmentsPerDay,
    required this.mostBookedDoctors,
    required this.bookingStatusBreakdown,
    required this.appointmentsToday,
    required this.bookedSlots,
    required this.totalSlots,
    required this.doctorUtilizationRate,
    required this.cancellationRate,
    required this.activeUsersWeekly,
    required this.pendingNotificationEvents,
    required this.pendingModerationEvents,
    required this.appliedModerationEvents,
  });
}

class _ReportPoint {
  final String label;
  final int value;

  const _ReportPoint({required this.label, required this.value});
}

DateTime _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) {
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _formatDay(DateTime dt) {
  return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}

String _moderationKindLabel(String kind) {
  switch (kind) {
    case 'patient_no_show_threshold_reached':
      return 'Patient no-show threshold reached';
    case 'doctor_cancellation_threshold_reached':
      return 'Doctor cancellation threshold reached';
    case 'doctor_account_deletion_request':
      return 'Doctor account deletion request';
    default:
      return kind.replaceAll('_', ' ');
  }
}

String _formatRange(DateTimeRange range) {
  final start = _formatDay(range.start);
  final end = _formatDay(range.end);
  return '$start - $end';
}

String _buildReportFileName() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'admin_report_$y$m$d.pdf';
}

Future<Uint8List> _buildAdminReportPdf(_AdminReportsData data) async {
  final doc = pw.Document();
  final now = DateTime.now();
  final generatedAt = _formatDateTime(now);

  pw.Widget metricCell(String title, String value) {
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdf.PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget pointTable(String title, List<_ReportPoint> points) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: pdf.PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: pdf.PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Label',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Value',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            ...points.map((point) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      point.label,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${point.value}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      maxPages: 100,
      build: (context) {
        return [
          pw.Text(
            'Admin Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated at: $generatedAt',
            style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              metricCell('Appointments today', '${data.appointmentsToday}'),
              metricCell('Active users (7d)', '${data.activeUsersWeekly}'),
              metricCell(
                'Cancellation rate',
                '${(data.cancellationRate * 100).toStringAsFixed(1)}%',
              ),
              metricCell(
                'Utilization (30d)',
                '${(data.doctorUtilizationRate * 100).toStringAsFixed(1)}%',
              ),
              metricCell('Booked slots (30d)', '${data.bookedSlots}'),
              metricCell('Total slots (30d)', '${data.totalSlots}'),
              metricCell(
                'Pending moderation',
                '${data.pendingModerationEvents}',
              ),
              metricCell(
                'Pending notifications',
                '${data.pendingNotificationEvents}',
              ),
              metricCell(
                'Applied moderation',
                '${data.appliedModerationEvents}',
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pointTable(
            'Booking status breakdown (30 days)',
            data.bookingStatusBreakdown,
          ),
          pw.SizedBox(height: 12),
          pointTable('Appointments per day (7 days)', data.appointmentsPerDay),
          pw.SizedBox(height: 12),
          pointTable('Most booked doctors', data.mostBookedDoctors),
        ];
      },
    ),
  );

  return doc.save();
}

Future<Map<String, String>> _prefetchDoctorNames(List<String> ids) async {
  if (ids.isEmpty) return {};
  final firestore = FirebaseFirestore.instance;
  final result = <String, String>{};
  const chunk = 10;
  for (var i = 0; i < ids.length; i += chunk) {
    final slice = ids.sublist(i, min(i + chunk, ids.length));
    final q = await firestore
        .collection('doctors')
        .where(FieldPath.documentId, whereIn: slice)
        .get();
    for (var d in q.docs) {
      final data = d.data();
      result[d.id] = (data['name'] as String?) ?? d.id;
    }
  }
  return result;
}

