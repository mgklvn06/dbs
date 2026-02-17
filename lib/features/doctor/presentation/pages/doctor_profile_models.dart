part of 'doctor_profile_page.dart';

class _AppointmentPreview {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String status;

  const _AppointmentPreview({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.status,
  });
}

class _DoctorDashboardMetrics {
  final int appointmentsToday;
  final int upcomingWeek;
  final int pendingApprovals;
  final bool availabilityActive;
  final List<_AppointmentPreview> nextAppointments;

  const _DoctorDashboardMetrics({
    required this.appointmentsToday,
    required this.upcomingWeek,
    required this.pendingApprovals,
    required this.availabilityActive,
    required this.nextAppointments,
  });
}

class _UserDetails {
  final String name;
  final String email;
  final String phone;

  const _UserDetails({
    required this.name,
    required this.email,
    required this.phone,
  });
}

class _PatientSummary {
  final String id;
  final DateTime lastVisit;
  final int count;

  const _PatientSummary({
    required this.id,
    required this.lastVisit,
    required this.count,
  });
}

class _AppointmentView {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String status;
  final String? notes;

  const _AppointmentView({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.status,
    required this.notes,
  });
}

class _AvailabilitySettings {
  final List<int> workingDays;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final String? breakStart;
  final String? breakEnd;
  final List<String> blockedDates;

  const _AvailabilitySettings({
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.breakStart,
    required this.breakEnd,
    required this.blockedDates,
  });

  Map<String, dynamic> toMap() {
    return {
      'workingDays': workingDays,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
      'blockedDates': blockedDates,
    };
  }

  factory _AvailabilitySettings.fromMap(Map<String, dynamic> map) {
    return _AvailabilitySettings(
      workingDays:
          (map['workingDays'] as List?)?.map((e) => e as int).toList() ??
          [1, 2, 3, 4, 5],
      startTime: (map['startTime'] as String?) ?? '09:00',
      endTime: (map['endTime'] as String?) ?? '17:00',
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      breakStart: map['breakStart'] as String?,
      breakEnd: map['breakEnd'] as String?,
      blockedDates:
          (map['blockedDates'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}

class _DoctorBookingActionPolicy {
  final bool doctorBookingEnabled;

  const _DoctorBookingActionPolicy({required this.doctorBookingEnabled});
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

String _formatDateKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatTimeKey(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh$mm';
}

String _formatTimeOfDay(TimeOfDay t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

TimeOfDay? _parseTimeOfDay(String input) {
  final value = input.trim();
  if (value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

int _minutesFromTime(TimeOfDay t) => t.hour * 60 + t.minute;

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<String> _parseBlockedDates(String input) {
  return input
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.length == 10)
      .toSet()
      .toList();
}

