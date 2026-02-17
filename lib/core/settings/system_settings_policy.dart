import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsPolicy {
  final bool maintenanceEnabled;
  final String maintenanceMessage;
  final bool allowNewPatients;
  final bool allowNewDoctors;
  final bool bookingEnabled;
  final bool doctorBookingEnabled;
  final int minNoticeHours;
  final int cancellationDeadlineHours;
  final int maxBookingsPerPatientPerDay;
  final int maxBookingsPerDoctorPerDay;
  final bool autoConfirm;

  final int autoSuspendAfterPatientNoShows;
  final int autoSuspendAfterDoctorCancellations;

  final bool emailNotificationsEnabled;
  final bool cancellationNotificationsEnabled;
  final bool doctorReminderEnabled;
  final bool patientReminderEnabled;
  final bool systemAlertsEnabled;

  final bool forceLogoutAllUsers;
  final DateTime? forceLogoutAt;
  final bool enforceUpdatedTerms;
  final int termsVersion;

  const SystemSettingsPolicy({
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.allowNewPatients,
    required this.allowNewDoctors,
    required this.bookingEnabled,
    required this.doctorBookingEnabled,
    required this.minNoticeHours,
    required this.cancellationDeadlineHours,
    required this.maxBookingsPerPatientPerDay,
    required this.maxBookingsPerDoctorPerDay,
    required this.autoConfirm,
    required this.autoSuspendAfterPatientNoShows,
    required this.autoSuspendAfterDoctorCancellations,
    required this.emailNotificationsEnabled,
    required this.cancellationNotificationsEnabled,
    required this.doctorReminderEnabled,
    required this.patientReminderEnabled,
    required this.systemAlertsEnabled,
    required this.forceLogoutAllUsers,
    required this.forceLogoutAt,
    required this.enforceUpdatedTerms,
    required this.termsVersion,
  });

  bool canSignIn({required bool isAdmin}) {
    return isAdmin || !maintenanceEnabled;
  }

  bool canRegisterPatient({required bool isAdmin}) {
    return isAdmin || (!maintenanceEnabled && allowNewPatients);
  }

  String maintenanceBlockedMessage() {
    final value = maintenanceMessage.trim();
    if (value.isNotEmpty) return value;
    return 'System is under maintenance. Please try again later.';
  }

  String patientRegistrationBlockedMessage() {
    if (maintenanceEnabled) return maintenanceBlockedMessage();
    if (!allowNewPatients) return 'New patient registrations are currently disabled.';
    return 'Registration is not available right now.';
  }

  bool shouldForceLogoutSession({
    required bool isAdmin,
    required DateTime? lastSignInAt,
  }) {
    if (isAdmin) return false;
    if (!forceLogoutAllUsers) return false;
    if (forceLogoutAt == null) return true;
    if (lastSignInAt == null) return true;
    return lastSignInAt.isBefore(forceLogoutAt!);
  }

  bool requiresTermsAcceptance({
    required bool isAdmin,
    required int acceptedTermsVersion,
  }) {
    if (isAdmin) return false;
    if (!enforceUpdatedTerms) return false;
    return acceptedTermsVersion < termsVersion;
  }

  static Future<SystemSettingsPolicy> load(FirebaseFirestore firestore) async {
    final settingsSnap = await firestore.collection('settings').doc('system').get();
    return SystemSettingsPolicy.fromMap(settingsSnap.data() ?? <String, dynamic>{});
  }

  factory SystemSettingsPolicy.fromMap(Map<String, dynamic> settings) {
    final maintenance = _readMap(settings['maintenance']);
    final registration = _readMap(settings['registration']);
    final booking = _readMap(settings['booking']);
    final moderation = _readMap(settings['moderation']);
    final notifications = _readMap(settings['notifications']);
    final security = _readMap(settings['security']);

    final maintenanceEnabled = (maintenance['enabled'] as bool?) ?? (settings['maintenanceMode'] as bool?) ?? false;
    final maintenanceMessage =
        (maintenance['message'] as String?) ?? 'System is under maintenance. Please try again later.';
    final allowNewPatients = (registration['allowNewPatients'] as bool?) ?? true;
    final allowNewDoctors =
        (registration['allowNewDoctors'] as bool?) ?? (settings['allowNewDoctors'] as bool?) ?? true;
    final bookingEnabled = (booking['enabled'] as bool?) ?? true;
    final doctorBookingEnabled = (booking['doctorBookingEnabled'] as bool?) ?? true;
    final autoConfirm = (booking['autoConfirm'] as bool?) ?? false;
    final forceLogoutAt = _readDateTime(
      security['forceLogoutAt'] ?? security['forceLogoutTimestamp'] ?? security['forceLogoutEpochMs'],
    );

    return SystemSettingsPolicy(
      maintenanceEnabled: maintenanceEnabled,
      maintenanceMessage: maintenanceMessage,
      allowNewPatients: allowNewPatients,
      allowNewDoctors: allowNewDoctors,
      bookingEnabled: bookingEnabled,
      doctorBookingEnabled: doctorBookingEnabled,
      minNoticeHours: _readInt(booking['minNoticeHours'], 2),
      cancellationDeadlineHours: _readInt(booking['cancellationDeadlineHours'], 3),
      maxBookingsPerPatientPerDay: _readInt(booking['maxBookingsPerPatientPerDay'], 2),
      maxBookingsPerDoctorPerDay: _readInt(booking['maxBookingsPerDoctorPerDay'], 15),
      autoConfirm: autoConfirm,
      autoSuspendAfterPatientNoShows: _readInt(moderation['autoSuspendAfterPatientNoShows'], 0),
      autoSuspendAfterDoctorCancellations: _readInt(moderation['autoSuspendAfterDoctorCancellations'], 0),
      emailNotificationsEnabled: (notifications['emailEnabled'] as bool?) ?? true,
      cancellationNotificationsEnabled: (notifications['cancellationEnabled'] as bool?) ?? true,
      doctorReminderEnabled: (notifications['doctorReminderEnabled'] as bool?) ?? true,
      patientReminderEnabled: (notifications['patientReminderEnabled'] as bool?) ?? true,
      systemAlertsEnabled: (notifications['systemAlertsEnabled'] as bool?) ?? true,
      forceLogoutAllUsers: (security['forceLogoutAllUsers'] as bool?) ?? false,
      forceLogoutAt: forceLogoutAt,
      enforceUpdatedTerms: (security['enforceUpdatedTerms'] as bool?) ?? false,
      termsVersion: _readInt(security['termsVersion'], 1),
    );
  }

  static Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  static DateTime? _readDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
