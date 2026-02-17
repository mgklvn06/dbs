part of 'patient_dashboard_page.dart';

class _AppointmentView {
  final String id;
  final String doctorId;
  final DateTime dateTime;
  final String status;
  final String? notes;

  const _AppointmentView({
    required this.id,
    required this.doctorId,
    required this.dateTime,
    required this.status,
    this.notes,
  });
}

class _DoctorSummary {
  final String id;
  final String name;
  final String specialty;
  final String? imageUrl;

  const _DoctorSummary({
    required this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
  });
}

class _PatientDashboardMetrics {
  final _AppointmentView? nextAppointment;
  final int upcomingCount;
  final int pastCount;
  final List<_DoctorSummary> recommendedDoctors;

  const _PatientDashboardMetrics({
    required this.nextAppointment,
    required this.upcomingCount,
    required this.pastCount,
    required this.recommendedDoctors,
  });
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

