// ignore_for_file: deprecated_member_use, use_build_context_synchronously

part of 'admin_dashboard.dart';

class _SettingsModule extends StatefulWidget {
  const _SettingsModule();

  @override
  State<_SettingsModule> createState() => _SettingsModuleState();
}

class _SettingsModuleState extends State<_SettingsModule> {
  final _maintenanceMessageController = TextEditingController();
  final _minNoticeController = TextEditingController();
  final _cancellationDeadlineController = TextEditingController();
  final _maxPatientPerDayController = TextEditingController();
  final _maxDoctorPerDayController = TextEditingController();
  final _patientNoShowsController = TextEditingController();
  final _doctorCancellationsController = TextEditingController();
  final _termsVersionController = TextEditingController();

  int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
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

  String _readString(dynamic raw, String fallback) {
    if (raw is String) return raw;
    if (raw == null) return fallback;
    return '$raw';
  }

  Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  DateTime? _readDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> _savePatch(
    DocumentReference<Map<String, dynamic>> settingsRef,
    Map<String, dynamic> patch,
  ) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown-admin';
    await settingsRef.set({
      ...patch,
      'system': {
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'updatedByAdminId': adminId,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    _minNoticeController.dispose();
    _cancellationDeadlineController.dispose();
    _maxPatientPerDayController.dispose();
    _maxDoctorPerDayController.dispose();
    _patientNoShowsController.dispose();
    _doctorCancellationsController.dispose();
    _termsVersionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsRef = FirebaseFirestore.instance
        .collection('settings')
        .doc('system');
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: settingsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: AppCard(
              child: Text(
                'Failed to load settings: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        try {
          final data = snapshot.data?.data() ?? {};
          final maintenance = _readMap(data['maintenance']);
          final registration = _readMap(data['registration']);
          final booking = _readMap(data['booking']);
          final moderation = _readMap(data['moderation']);
          final notifications = _readMap(data['notifications']);
          final security = _readMap(data['security']);

          final maintenanceEnabled = _readBool(
            maintenance['enabled'],
            _readBool(data['maintenanceMode'], false),
          );
          final maintenanceMessage = _readString(
            maintenance['message'],
            'System under maintenance. Please try again later.',
          );

          final allowNewPatients = _readBool(
            registration['allowNewPatients'],
            true,
          );
          final allowNewDoctors = _readBool(
            registration['allowNewDoctors'],
            _readBool(data['allowNewDoctors'], true),
          );
          final requireDoctorApproval = _readBool(
            registration['requireDoctorApproval'],
            true,
          );

          final bookingEnabled = _readBool(booking['enabled'], true);
          final doctorBookingEnabled = _readBool(
            booking['doctorBookingEnabled'],
            true,
          );
          final autoConfirm = _readBool(booking['autoConfirm'], false);
          final minNoticeHours = _readInt(booking['minNoticeHours'], 2);
          final cancellationDeadlineHours = _readInt(
            booking['cancellationDeadlineHours'],
            3,
          );
          final maxBookingsPerPatientPerDay = _readInt(
            booking['maxBookingsPerPatientPerDay'],
            2,
          );
          final maxBookingsPerDoctorPerDay = _readInt(
            booking['maxBookingsPerDoctorPerDay'],
            15,
          );
          final autoSuspendAfterPatientNoShows = _readInt(
            moderation['autoSuspendAfterPatientNoShows'],
            0,
          );
          final autoSuspendAfterDoctorCancellations = _readInt(
            moderation['autoSuspendAfterDoctorCancellations'],
            0,
          );

          final emailEnabled = _readBool(notifications['emailEnabled'], true);
          final cancellationEnabled = _readBool(
            notifications['cancellationEnabled'],
            true,
          );
          final doctorReminderEnabled = _readBool(
            notifications['doctorReminderEnabled'],
            true,
          );
          final patientReminderEnabled = _readBool(
            notifications['patientReminderEnabled'],
            true,
          );
          final systemAlertsEnabled = _readBool(
            notifications['systemAlertsEnabled'],
            true,
          );

          final forceLogoutAllUsers = _readBool(
            security['forceLogoutAllUsers'],
            false,
          );
          final forceLogoutAt = _readDateTime(
            security['forceLogoutAt'] ??
                security['forceLogoutTimestamp'] ??
                security['forceLogoutEpochMs'],
          );
          final enforceUpdatedTerms = _readBool(
            security['enforceUpdatedTerms'],
            false,
          );
          final termsVersion = max(1, _readInt(security['termsVersion'], 1));

          if (_maintenanceMessageController.text != maintenanceMessage) {
            _maintenanceMessageController.text = maintenanceMessage;
          }
          if (_minNoticeController.text != '$minNoticeHours') {
            _minNoticeController.text = '$minNoticeHours';
          }
          if (_cancellationDeadlineController.text !=
              '$cancellationDeadlineHours') {
            _cancellationDeadlineController.text = '$cancellationDeadlineHours';
          }
          if (_maxPatientPerDayController.text !=
              '$maxBookingsPerPatientPerDay') {
            _maxPatientPerDayController.text = '$maxBookingsPerPatientPerDay';
          }
          if (_maxDoctorPerDayController.text !=
              '$maxBookingsPerDoctorPerDay') {
            _maxDoctorPerDayController.text = '$maxBookingsPerDoctorPerDay';
          }
          if (_patientNoShowsController.text !=
              '$autoSuspendAfterPatientNoShows') {
            _patientNoShowsController.text = '$autoSuspendAfterPatientNoShows';
          }
          if (_doctorCancellationsController.text !=
              '$autoSuspendAfterDoctorCancellations') {
            _doctorCancellationsController.text =
                '$autoSuspendAfterDoctorCancellations';
          }
          if (_termsVersionController.text != '$termsVersion') {
            _termsVersionController.text = '$termsVersion';
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Configure operational limits and access policies.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: maintenanceEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'maintenance': {'enabled': value},
                              'maintenanceMode': value,
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Maintenance mode'),
                        subtitle: const Text(
                          'Disable booking and sign-ins for non-admin users',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: bookingEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'booking': {'enabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Booking enabled'),
                        subtitle: const Text(
                          'Allow patients to create new bookings',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: doctorBookingEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'booking': {'doctorBookingEnabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Doctor booking actions enabled'),
                        subtitle: const Text(
                          'Allow doctors to confirm/cancel/complete appointments',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: allowNewPatients,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'registration': {'allowNewPatients': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Allow new patients'),
                        subtitle: const Text(
                          'Permit new patient registrations',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: allowNewDoctors,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'registration': {'allowNewDoctors': value},
                              'allowNewDoctors': value,
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Allow new doctors'),
                        subtitle: const Text(
                          'Permit doctors to create profiles and submit availability',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: requireDoctorApproval,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'registration': {'requireDoctorApproval': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Require doctor approval'),
                        subtitle: const Text(
                          'Keep doctors in pending state until approved by admin',
                        ),
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
                        'Maintenance message',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _maintenanceMessageController,
                        decoration: const InputDecoration(
                          labelText: 'Message shown during maintenance',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _savePatch(settingsRef, {
                                'maintenance': {
                                  'message': _maintenanceMessageController.text
                                      .trim(),
                                },
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Maintenance message saved'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save settings: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save message'),
                        ),
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
                        'Booking rules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minNoticeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum hours before booking allowed',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cancellationDeadlineController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              'Cancellation deadline (hours before appointment)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _maxPatientPerDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max bookings per patient per day',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _maxDoctorPerDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max bookings per doctor per day',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: autoConfirm,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'booking': {'autoConfirm': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Auto-confirm booking'),
                        subtitle: const Text(
                          'New appointments are immediately confirmed',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final minNotice = _readInt(
                              _minNoticeController.text.trim(),
                              minNoticeHours,
                            );
                            final cancellationDeadline = _readInt(
                              _cancellationDeadlineController.text.trim(),
                              cancellationDeadlineHours,
                            );
                            final maxPatient = _readInt(
                              _maxPatientPerDayController.text.trim(),
                              maxBookingsPerPatientPerDay,
                            );
                            final maxDoctor = _readInt(
                              _maxDoctorPerDayController.text.trim(),
                              maxBookingsPerDoctorPerDay,
                            );
                            try {
                              await _savePatch(settingsRef, {
                                'booking': {
                                  'minNoticeHours': max(0, minNotice),
                                  'cancellationDeadlineHours': max(
                                    0,
                                    cancellationDeadline,
                                  ),
                                  'maxBookingsPerPatientPerDay': max(
                                    0,
                                    maxPatient,
                                  ),
                                  'maxBookingsPerDoctorPerDay': max(
                                    0,
                                    maxDoctor,
                                  ),
                                },
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings saved')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save settings: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save settings'),
                        ),
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
                        'Moderation rules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _patientNoShowsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              'Auto-suspend patient after no-shows (0 = off)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _doctorCancellationsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText:
                              'Auto-suspend doctor after cancellations (0 = off)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final patientNoShows = _readInt(
                              _patientNoShowsController.text.trim(),
                              autoSuspendAfterPatientNoShows,
                            );
                            final doctorCancels = _readInt(
                              _doctorCancellationsController.text.trim(),
                              autoSuspendAfterDoctorCancellations,
                            );
                            try {
                              await _savePatch(settingsRef, {
                                'moderation': {
                                  'autoSuspendAfterPatientNoShows': max(
                                    0,
                                    patientNoShows,
                                  ),
                                  'autoSuspendAfterDoctorCancellations': max(
                                    0,
                                    doctorCancels,
                                  ),
                                },
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Moderation settings saved'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save settings: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save moderation'),
                        ),
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
                        'Notification settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: emailEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'notifications': {'emailEnabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Email notifications enabled'),
                        subtitle: const Text(
                          'Master switch for email/send queues',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: cancellationEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'notifications': {'cancellationEnabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Cancellation notifications'),
                        subtitle: const Text(
                          'Queue notifications when appointments are cancelled',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: doctorReminderEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'notifications': {'doctorReminderEnabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Doctor reminder notifications'),
                        subtitle: const Text(
                          'Allow doctor-oriented appointment updates',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: patientReminderEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'notifications': {
                                'patientReminderEnabled': value,
                              },
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Patient reminder notifications'),
                        subtitle: const Text(
                          'Allow patient-oriented appointment updates',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: systemAlertsEnabled,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'notifications': {'systemAlertsEnabled': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('System alert notifications'),
                        subtitle: const Text(
                          'Queue non-cancellation status changes',
                        ),
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
                        'Security controls',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: enforceUpdatedTerms,
                        onChanged: (value) async {
                          try {
                            await _savePatch(settingsRef, {
                              'security': {'enforceUpdatedTerms': value},
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update setting: $e'),
                              ),
                            );
                          }
                        },
                        title: const Text('Enforce updated terms'),
                        subtitle: const Text(
                          'Require users to accept the latest terms version',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _termsVersionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Terms version (integer)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final nextTermsVersion = max(
                                1,
                                _readInt(
                                  _termsVersionController.text.trim(),
                                  termsVersion,
                                ),
                              );
                              try {
                                await _savePatch(settingsRef, {
                                  'security': {
                                    'termsVersion': nextTermsVersion,
                                  },
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Security settings saved'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to save settings: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save security'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await _savePatch(settingsRef, {
                                  'security': {
                                    'forceLogoutAllUsers': !forceLogoutAllUsers,
                                    if (!forceLogoutAllUsers)
                                      'forceLogoutAt':
                                          FieldValue.serverTimestamp(),
                                  },
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !forceLogoutAllUsers
                                          ? 'Force logout activated'
                                          : 'Force logout disabled',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update setting: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: Text(
                              forceLogoutAllUsers
                                  ? 'Disable force logout'
                                  : 'Force logout all users',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        forceLogoutAt == null
                            ? 'Last force logout: never'
                            : 'Last force logout: ${_formatDateTime(forceLogoutAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return Center(
            child: AppCard(
              child: Text(
                'Failed to render settings: $e',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      },
    );
  }
}

