// ignore_for_file: deprecated_member_use, use_build_context_synchronously

part of 'admin_dashboard.dart';

class _BasicSettingsModule extends StatefulWidget {
  const _BasicSettingsModule();

  @override
  State<_BasicSettingsModule> createState() => _BasicSettingsModuleState();
}

class _BasicSettingsModuleState extends State<_BasicSettingsModule> {
  final _maintenanceMessageController = TextEditingController();
  final _minNoticeController = TextEditingController();
  final _cancellationDeadlineController = TextEditingController();

  Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((key, value) => MapEntry('$key', value));
    return <String, dynamic>{};
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

  int _readInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  String _readString(dynamic raw, String fallback) {
    if (raw is String && raw.trim().isNotEmpty) return raw;
    if (raw == null) return fallback;
    return '$raw';
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

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final maintenance = _readMap(data['maintenance']);
        final registration = _readMap(data['registration']);
        final booking = _readMap(data['booking']);

        final maintenanceEnabled = _readBool(
          maintenance['enabled'],
          _readBool(data['maintenanceMode'], false),
        );
        final bookingEnabled = _readBool(booking['enabled'], true);
        final allowNewPatients = _readBool(
          registration['allowNewPatients'],
          true,
        );
        final allowNewDoctors = _readBool(
          registration['allowNewDoctors'],
          _readBool(data['allowNewDoctors'], true),
        );
        final maintenanceMessage = _readString(
          maintenance['message'],
          'System under maintenance. Please try again later.',
        );
        final minNoticeHours = _readInt(booking['minNoticeHours'], 2);
        final cancellationDeadlineHours = _readInt(
          booking['cancellationDeadlineHours'],
          3,
        );

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

        return ListView(
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
                    'Core controls only (stable mode).',
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
                  ElevatedButton.icon(
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
                      labelText: 'Minimum hours before booking',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cancellationDeadlineController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cancellation deadline (hours)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final minNotice = _readInt(
                        _minNoticeController.text.trim(),
                        minNoticeHours,
                      );
                      final cancellationDeadline = _readInt(
                        _cancellationDeadlineController.text.trim(),
                        cancellationDeadlineHours,
                      );
                      try {
                        await _savePatch(settingsRef, {
                          'booking': {
                            'minNoticeHours': max(0, minNotice),
                            'cancellationDeadlineHours': max(
                              0,
                              cancellationDeadline,
                            ),
                          },
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking rules saved')),
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
                    label: const Text('Save booking rules'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

