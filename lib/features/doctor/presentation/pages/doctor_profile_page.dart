
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _navItems = const [
    _DoctorNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _DoctorNavItem(label: 'My Schedule', icon: Icons.calendar_month_outlined),
    _DoctorNavItem(label: 'Appointments', icon: Icons.event_note_outlined),
    _DoctorNavItem(label: 'Availability', icon: Icons.schedule_outlined),
    _DoctorNavItem(label: 'Patients', icon: Icons.people_outline),
    _DoctorNavItem(label: 'Profile Settings', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 0;

  final TextEditingController _appointmentSearchController = TextEditingController();
  final TextEditingController _patientSearchController = TextEditingController();

  String _appointmentQuery = '';
  String _patientQuery = '';
  String _statusFilter = 'all';

  DateTime _selectedDay = DateTime.now();
  bool _weeklyView = false;

  late Future<_DoctorDashboardMetrics> _metricsFuture;

  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profileSpecialtyController = TextEditingController();
  final TextEditingController _profileBioController = TextEditingController();
  final TextEditingController _profileExperienceController = TextEditingController();
  final TextEditingController _profileFeeController = TextEditingController();
  final TextEditingController _profileImageController = TextEditingController();
  final TextEditingController _profileContactEmailController = TextEditingController();
  final TextEditingController _profileContactPhoneController = TextEditingController();

  final TextEditingController _availStartController = TextEditingController(text: '09:00');
  final TextEditingController _availEndController = TextEditingController(text: '17:00');
  final TextEditingController _availSlotDurationController = TextEditingController(text: '30');
  final TextEditingController _availBreakStartController = TextEditingController(text: '12:00');
  final TextEditingController _availBreakEndController = TextEditingController(text: '13:00');
  final TextEditingController _availBlockedDatesController = TextEditingController();

  final Set<int> _workingDays = {1, 2, 3, 4, 5};

  bool _profileLoaded = false;
  bool _availabilityLoaded = false;
  bool _isGeneratingSlots = false;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadDashboardMetrics();
  }

  @override
  void dispose() {
    _appointmentSearchController.dispose();
    _patientSearchController.dispose();
    _profileNameController.dispose();
    _profileSpecialtyController.dispose();
    _profileBioController.dispose();
    _profileExperienceController.dispose();
    _profileFeeController.dispose();
    _profileImageController.dispose();
    _profileContactEmailController.dispose();
    _profileContactPhoneController.dispose();
    _availStartController.dispose();
    _availEndController.dispose();
    _availSlotDurationController.dispose();
    _availBreakStartController.dispose();
    _availBreakEndController.dispose();
    _availBlockedDatesController.dispose();
    super.dispose();
  }

  void _selectModule(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _metricsFuture = _loadDashboardMetrics();
    });
  }

  String? _currentDoctorId() => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again.')),
      );
    }

    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return Scaffold(
          appBar: AppBar(
            title: Text(_navItems[_selectedIndex].label),
            automaticallyImplyLeading: !isWide,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (_selectedIndex == 0) {
                    _refreshDashboard();
                  } else {
                    setState(() {});
                  }
                },
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: isWide ? null : Drawer(child: _buildSidebar(context, inDrawer: true)),
          body: AppBackground(
            child: Row(
              children: [
                if (isWide)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
                    child: SizedBox(
                      width: 260,
                      child: _buildSidebar(context, inDrawer: false),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isWide ? 10 : 20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _navItems[_selectedIndex].label,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _QuickActionChip(
                                  label: 'My schedule',
                                  icon: Icons.calendar_today_outlined,
                                  onTap: () => _selectModule(1),
                                ),
                                const SizedBox(width: 10),
                                _QuickActionChip(
                                  label: 'Availability',
                                  icon: Icons.schedule_outlined,
                                  onTap: () => _selectModule(3),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _buildModule(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildSidebar(BuildContext context, {required bool inDrawer}) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.medical_services, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor Console',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Care delivery tools',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _navItems.length; i += 1)
            _NavTile(
              item: _navItems[i],
              selected: _selectedIndex == i,
              onTap: () {
                _selectModule(i);
                if (inDrawer) Navigator.pop(context);
              },
            ),
          const Spacer(),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Signed in',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, Routes.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildModule(BuildContext context) {
    final doctorId = _currentDoctorId();
    if (doctorId == null) {
      return const _EmptyStateCard(message: 'Doctor session not available.');
    }

    switch (_selectedIndex) {
      case 0:
        return _DoctorDashboardModule(
          metricsFuture: _metricsFuture,
          onRefresh: _refreshDashboard,
          fetchNames: _prefetchUserNames,
        );
      case 1:
        return _DoctorScheduleModule(
          doctorId: doctorId,
          selectedDay: _selectedDay,
          weeklyView: _weeklyView,
          onDayChanged: (value) => setState(() => _selectedDay = value),
          onViewChanged: (value) => setState(() => _weeklyView = value),
          onBlockTime: () => _promptBlockTime(context, doctorId),
          fetchNames: _prefetchUserNames,
        );
      case 2:
        return _DoctorAppointmentsModule(
          doctorId: doctorId,
          searchController: _appointmentSearchController,
          query: _appointmentQuery,
          statusFilter: _statusFilter,
          onQueryChanged: (value) => setState(() => _appointmentQuery = value),
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          fetchNames: _prefetchUserNames,
          onUpdateStatus: (id, status) => _updateAppointmentStatus(context, id, status),
          onAddNotes: (id, current) => _promptAppointmentNotes(context, id, current),
        );
      case 3:
        return _DoctorAvailabilityModule(
          doctorId: doctorId,
          startController: _availStartController,
          endController: _availEndController,
          slotDurationController: _availSlotDurationController,
          breakStartController: _availBreakStartController,
          breakEndController: _availBreakEndController,
          blockedDatesController: _availBlockedDatesController,
          workingDays: _workingDays,
          isGenerating: _isGeneratingSlots,
          onToggleDay: (day) => setState(() {
            if (_workingDays.contains(day)) {
              _workingDays.remove(day);
            } else {
              _workingDays.add(day);
            }
          }),
          onSaveSettings: () => _saveAvailabilitySettings(context, doctorId),
          onGenerateSlots: () => _generateSlotsForNext14Days(context, doctorId),
          onBlockTime: () => _promptBlockTime(context, doctorId),
          onLoadSettings: _loadAvailabilitySettings,
          availabilityLoaded: _availabilityLoaded,
          setAvailabilityLoaded: (value) => _availabilityLoaded = value,
        );
      case 4:
        return _DoctorPatientsModule(
          doctorId: doctorId,
          searchController: _patientSearchController,
          query: _patientQuery,
          onQueryChanged: (value) => setState(() => _patientQuery = value),
          fetchUserDetails: _prefetchUserDetails,
          onViewHistory: (id, name) => _showUserAppointmentHistory(context, doctorId, id, name),
        );
      case 5:
        return _DoctorProfileSettingsModule(
          doctorId: doctorId,
          nameController: _profileNameController,
          specialtyController: _profileSpecialtyController,
          bioController: _profileBioController,
          experienceController: _profileExperienceController,
          feeController: _profileFeeController,
          imageController: _profileImageController,
          contactEmailController: _profileContactEmailController,
          contactPhoneController: _profileContactPhoneController,
          onSaveProfile: () => _saveProfile(context, doctorId),
          onLoadProfile: _loadProfileFields,
          profileLoaded: _profileLoaded,
          setProfileLoaded: (value) => _profileLoaded = value,
        );
      default:
        return const SizedBox.shrink();
    }
  }
  Future<void> _updateAppointmentStatus(BuildContext context, String appointmentId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment updated: $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Future<void> _promptAppointmentNotes(BuildContext context, String appointmentId, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Appointment notes'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Add notes for this appointment'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'notes': result,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
    }
  }

  Future<void> _saveProfile(BuildContext context, String doctorId) async {
    final name = _profileNameController.text.trim();
    final specialty = _profileSpecialtyController.text.trim();
    final bio = _profileBioController.text.trim();
    final exp = int.tryParse(_profileExperienceController.text.trim());
    final fee = double.tryParse(_profileFeeController.text.trim());
    final image = _profileImageController.text.trim();
    final contactEmail = _profileContactEmailController.text.trim();
    final contactPhone = _profileContactPhoneController.text.trim();

    final payload = <String, dynamic>{
      'name': name,
      'specialty': specialty,
      'bio': bio,
      if (exp != null) 'experienceYears': exp,
      if (fee != null) 'consultationFee': fee,
      if (image.isNotEmpty) 'profileImageUrl': image,
      if (contactEmail.isNotEmpty) 'contactEmail': contactEmail,
      if (contactPhone.isNotEmpty) 'contactPhone': contactPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('doctors').doc(doctorId).set(payload, SetOptions(merge: true));
      if (name.isNotEmpty) {
        await db.collection('users').doc(doctorId).set({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  void _loadProfileFields(Map<String, dynamic>? data) {
    if (_profileLoaded || data == null) return;
    _profileNameController.text = (data['name'] as String?) ?? '';
    _profileSpecialtyController.text = (data['specialty'] as String?) ?? '';
    _profileBioController.text = (data['bio'] as String?) ?? '';
    final exp = data['experienceYears'];
    _profileExperienceController.text = exp == null ? '' : exp.toString();
    final fee = data['consultationFee'];
    _profileFeeController.text = fee == null ? '' : fee.toString();
    _profileImageController.text = (data['profileImageUrl'] as String?) ?? '';
    _profileContactEmailController.text = (data['contactEmail'] as String?) ?? '';
    _profileContactPhoneController.text = (data['contactPhone'] as String?) ?? '';
    _profileLoaded = true;
  }

  Future<void> _saveAvailabilitySettings(BuildContext context, String doctorId) async {
    final start = _parseTimeOfDay(_availStartController.text.trim());
    final end = _parseTimeOfDay(_availEndController.text.trim());
    final duration = int.tryParse(_availSlotDurationController.text.trim()) ?? 0;
    if (start == null || end == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check availability times and duration.')),
      );
      return;
    }

    final settings = _AvailabilitySettings(
      workingDays: _workingDays.toList()..sort(),
      startTime: _formatTimeOfDay(start),
      endTime: _formatTimeOfDay(end),
      slotDurationMinutes: duration,
      breakStart: _availBreakStartController.text.trim().isEmpty
          ? null
          : _availBreakStartController.text.trim(),
      breakEnd: _availBreakEndController.text.trim().isEmpty
          ? null
          : _availBreakEndController.text.trim(),
      blockedDates: _parseBlockedDates(_availBlockedDatesController.text),
    );

    try {
      await FirebaseFirestore.instance.collection('doctors').doc(doctorId).set({
        'availabilitySettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save availability: $e')));
    }
  }

  void _loadAvailabilitySettings(Map<String, dynamic>? data) {
    if (_availabilityLoaded || data == null) return;
    final raw = data['availabilitySettings'];
    if (raw is Map<String, dynamic>) {
      final settings = _AvailabilitySettings.fromMap(raw);
      _workingDays
        ..clear()
        ..addAll(settings.workingDays);
      _availStartController.text = settings.startTime;
      _availEndController.text = settings.endTime;
      _availSlotDurationController.text = settings.slotDurationMinutes.toString();
      _availBreakStartController.text = settings.breakStart ?? '';
      _availBreakEndController.text = settings.breakEnd ?? '';
      _availBlockedDatesController.text = settings.blockedDates.join(', ');
    }
    _availabilityLoaded = true;
  }

  Future<void> _generateSlotsForNext14Days(BuildContext context, String doctorId) async {
    if (_isGeneratingSlots) return;
    final start = _parseTimeOfDay(_availStartController.text.trim());
    final end = _parseTimeOfDay(_availEndController.text.trim());
    final duration = int.tryParse(_availSlotDurationController.text.trim()) ?? 0;
    final breakStart = _parseTimeOfDay(_availBreakStartController.text.trim());
    final breakEnd = _parseTimeOfDay(_availBreakEndController.text.trim());

    if (start == null || end == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check availability times and duration.')),
      );
      return;
    }

    setState(() => _isGeneratingSlots = true);

    final rangeStart = _dateOnly(DateTime.now());
    final rangeEnd = rangeStart.add(const Duration(days: 14));

    try {
      await _generateSlotsForRange(
        doctorId,
        rangeStart,
        rangeEnd,
        start,
        end,
        duration,
        breakStart,
        breakEnd,
        _parseBlockedDates(_availBlockedDatesController.text),
        _workingDays.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slots generated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate slots: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingSlots = false);
    }
  }

  Future<void> _generateSlotsForRange(
    String doctorId,
    DateTime rangeStart,
    DateTime rangeEnd,
    TimeOfDay start,
    TimeOfDay end,
    int durationMinutes,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
    List<String> blockedDates,
    List<int> workingDays,
  ) async {
    final db = FirebaseFirestore.instance;
    final slotsRef = db.collection('availability').doc(doctorId).collection('slots');
    final existingSnap = await slotsRef
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .where('startTime', isLessThan: Timestamp.fromDate(rangeEnd))
        .get();
    final existingIds = existingSnap.docs.map((d) => d.id).toSet();

    final startMinutes = _minutesFromTime(start);
    final endMinutes = _minutesFromTime(end);
    final breakStartMinutes = breakStart == null ? null : _minutesFromTime(breakStart);
    final breakEndMinutes = breakEnd == null ? null : _minutesFromTime(breakEnd);

    var batch = db.batch();
    var ops = 0;

    for (var day = rangeStart; day.isBefore(rangeEnd); day = day.add(const Duration(days: 1))) {
      if (!workingDays.contains(day.weekday)) continue;
      final dayKey = _formatDateKey(day);
      if (blockedDates.contains(dayKey)) continue;

      for (var m = startMinutes; m + durationMinutes <= endMinutes; m += durationMinutes) {
        if (breakStartMinutes != null && breakEndMinutes != null) {
          final overlap = m < breakEndMinutes && (m + durationMinutes) > breakStartMinutes;
          if (overlap) continue;
        }
        final slotStart = DateTime(day.year, day.month, day.day).add(Duration(minutes: m));
        final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
        final slotId = 'slot_${_formatDateKey(day)}_${_formatTimeKey(slotStart)}';
        if (existingIds.contains(slotId)) continue;

        batch.set(slotsRef.doc(slotId), {
          'startTime': Timestamp.fromDate(slotStart),
          'endTime': Timestamp.fromDate(slotEnd),
          'isBooked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        ops += 1;

        if (ops >= 450) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }
    }

    if (ops > 0) {
      await batch.commit();
    }
  }

  Future<void> _promptBlockTime(BuildContext context, String doctorId) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (pickedTime == null) return;

    final durationController = TextEditingController(text: '30');
    final duration = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block time duration (minutes)'),
          content: TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutes'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(durationController.text.trim()) ?? 0;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    durationController.dispose();
    if (duration == null || duration <= 0) return;

    final slotStart = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    final slotEnd = slotStart.add(Duration(minutes: duration));
    final slotId = 'slot_${_formatDateKey(slotStart)}_${_formatTimeKey(slotStart)}';
    final slotRef = FirebaseFirestore.instance
        .collection('availability')
        .doc(doctorId)
        .collection('slots')
        .doc(slotId);

    final existing = await slotRef.get();
    if (existing.exists) {
      final data = existing.data();
      final isBooked = (data?['isBooked'] as bool?) ?? false;
      final bookedBy = data?['bookedBy'] as String?;
      if (isBooked && bookedBy != doctorId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot already booked by a patient.')),
        );
        return;
      }
      await slotRef.update({
        'isBooked': true,
        'bookedBy': doctorId,
        'blockedReason': 'manual',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await slotRef.set({
        'startTime': Timestamp.fromDate(slotStart),
        'endTime': Timestamp.fromDate(slotEnd),
        'isBooked': true,
        'bookedBy': doctorId,
        'blockedReason': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time blocked')));
  }
  Future<_DoctorDashboardMetrics> _loadDashboardMetrics() async {
    final doctorId = _currentDoctorId();
    if (doctorId == null) {
      return const _DoctorDashboardMetrics(
        appointmentsToday: 0,
        upcomingWeek: 0,
        pendingApprovals: 0,
        availabilityActive: false,
        nextAppointments: [],
      );
    }

    final db = FirebaseFirestore.instance;
    final apptsSnap = await db.collection('appointments').where('doctorId', isEqualTo: doctorId).get();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));

    var todayCount = 0;
    var upcomingCount = 0;
    var pendingCount = 0;
    final upcomingList = <_AppointmentPreview>[];

    for (final doc in apptsSnap.docs) {
      final data = doc.data();
      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final status = (data['status'] as String?) ?? 'pending';
      if (dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) && dt.isBefore(tomorrow)) {
        todayCount += 1;
      }
      if (dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) && dt.isBefore(weekEnd)) {
        upcomingCount += 1;
      }
      if (status == 'pending') {
        pendingCount += 1;
      }
      if (dt.isAfter(now)) {
        upcomingList.add(_AppointmentPreview(
          id: doc.id,
          patientId: (data['userId'] as String?) ?? '',
          dateTime: dt,
          status: status,
        ));
      }
    }

    upcomingList.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final nextAppointments = upcomingList.take(5).toList();

    bool availabilityActive = false;
    final slotsSnap = await db
        .collection('availability')
        .doc(doctorId)
        .collection('slots')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .limit(20)
        .get();
    for (final doc in slotsSnap.docs) {
      final data = doc.data();
      final isBooked = (data['isBooked'] as bool?) ?? false;
      if (!isBooked) {
        availabilityActive = true;
        break;
      }
    }

    return _DoctorDashboardMetrics(
      appointmentsToday: todayCount,
      upcomingWeek: upcomingCount,
      pendingApprovals: pendingCount,
      availabilityActive: availabilityActive,
      nextAppointments: nextAppointments,
    );
  }

  Future<Map<String, String>> _prefetchUserNames(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final users = <String, String>{};
    final list = ids.where((id) => id.isNotEmpty).toList();
    const chunk = 10;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, min(i + chunk, list.length));
      final q = await firestore.collection('users').where(FieldPath.documentId, whereIn: slice).get();
      for (final doc in q.docs) {
        final data = doc.data();
        users[doc.id] = (data['displayName'] as String?) ?? (data['email'] as String?) ?? doc.id;
      }
    }
    return users;
  }

  Future<Map<String, _UserDetails>> _prefetchUserDetails(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final users = <String, _UserDetails>{};
    final list = ids.where((id) => id.isNotEmpty).toList();
    const chunk = 10;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, min(i + chunk, list.length));
      final q = await firestore.collection('users').where(FieldPath.documentId, whereIn: slice).get();
      for (final doc in q.docs) {
        final data = doc.data();
        final name = (data['displayName'] as String?) ?? (data['email'] as String?) ?? doc.id;
        final email = (data['email'] as String?) ?? '';
        final phone = (data['phone'] as String?) ?? '';
        users[doc.id] = _UserDetails(name: name, email: email, phone: phone);
      }
    }
    return users;
  }

  Future<void> _showUserAppointmentHistory(
    BuildContext context,
    String doctorId,
    String userId,
    String userName,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('userId', isEqualTo: userId)
        .get();
    final docs = snap.docs.toList();
    docs.sort((a, b) {
      final adt = _parseDate(a.data()['appointmentTime'] ?? a.data()['dateTime']);
      final bdt = _parseDate(b.data()['appointmentTime'] ?? b.data()['dateTime']);
      return bdt.compareTo(adt);
    });

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('History: $userName'),
          content: SizedBox(
            width: 440,
            child: docs.isEmpty
                ? const Text('No appointments found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                      final status = (data['status'] as String?) ?? 'pending';
                      return ListTile(
                        dense: true,
                        title: Text(_formatDateTime(dt)),
                        subtitle: Text('Status: $status'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: docs.length,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
class _DoctorNavItem {
  final String label;
  final IconData icon;

  const _DoctorNavItem({required this.label, required this.icon});
}

class _NavTile extends StatelessWidget {
  final _DoctorNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? accent;

  const _MetricCard({required this.title, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
class _DoctorDashboardModule extends StatelessWidget {
  final Future<_DoctorDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;
  final Future<Map<String, String>> Function(Set<String> ids) fetchNames;

  const _DoctorDashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
    required this.fetchNames,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DoctorDashboardMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }
        final data = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Today overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(title: 'Appointments today', value: data.appointmentsToday.toString()),
                          _MetricCard(title: 'Upcoming this week', value: data.upcomingWeek.toString()),
                          _MetricCard(title: 'Pending approvals', value: data.pendingApprovals.toString()),
                          _MetricCard(
                            title: 'Availability',
                            value: data.availabilityActive ? 'Active' : 'Inactive',
                            accent: data.availabilityActive ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next appointments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (data.nextAppointments.isEmpty)
                      const Text('No upcoming appointments')
                    else
                      FutureBuilder<Map<String, String>>(
                        future: fetchNames(data.nextAppointments.map((e) => e.patientId).toSet()),
                        builder: (context, nameSnap) {
                          final names = nameSnap.data ?? {};
                          return Column(
                            children: data.nextAppointments.map((appt) {
                              final pname = names[appt.patientId] ?? appt.patientId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pname,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text(_formatDateTime(appt.dateTime)),
                                    const SizedBox(width: 12),
                                    _StatusPill(label: appt.status, active: appt.status == 'confirmed' || appt.status == 'pending'),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _DoctorScheduleModule extends StatelessWidget {
  final String doctorId;
  final DateTime selectedDay;
  final bool weeklyView;
  final ValueChanged<DateTime> onDayChanged;
  final ValueChanged<bool> onViewChanged;
  final VoidCallback onBlockTime;
  final Future<Map<String, String>> Function(Set<String> ids) fetchNames;

  const _DoctorScheduleModule({
    required this.doctorId,
    required this.selectedDay,
    required this.weeklyView,
    required this.onDayChanged,
    required this.onViewChanged,
    required this.onBlockTime,
    required this.fetchNames,
  });

  @override
  Widget build(BuildContext context) {
    final start = weeklyView ? _weekStart(selectedDay) : _dateOnly(selectedDay);
    final end = weeklyView ? start.add(const Duration(days: 7)) : start.add(const Duration(days: 1));
    final title = weeklyView ? 'Week of ${_formatDay(start)}' : _formatDay(start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Review daily or weekly appointments and block time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Daily'),
                    selected: !weeklyView,
                    onSelected: (v) {
                      if (v) onViewChanged(false);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Weekly'),
                    selected: weeklyView,
                    onSelected: (v) {
                      if (v) onViewChanged(true);
                    },
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 1),
                        initialDate: selectedDay,
                      );
                      if (picked != null) onDayChanged(picked);
                    },
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(title),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onBlockTime,
                    icon: const Icon(Icons.block),
                    label: const Text('Block time'),
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
                  .collection('appointments')
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load schedule'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No appointments found'));
                }

                final list = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                  if (dt.isBefore(start) || !dt.isBefore(end)) continue;
                  list.add(_AppointmentView(
                    id: doc.id,
                    patientId: (data['userId'] as String?) ?? '',
                    dateTime: dt,
                    status: (data['status'] as String?) ?? 'pending',
                    notes: data['notes'] as String?,
                  ));
                }

                if (list.isEmpty) {
                  return const Center(child: Text('No appointments in this range'));
                }

                list.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchNames(list.map((e) => e.patientId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = list[index];
                        final pname = names[appt.patientId] ?? appt.patientId;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pname,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusPill(
                                    label: appt.status,
                                    active: appt.status == 'confirmed' || appt.status == 'pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatDateTime(appt.dateTime)),
                              if ((appt.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Notes: ${appt.notes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
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
}
class _DoctorAppointmentsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController searchController;
  final String query;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<Map<String, String>> Function(Set<String> ids) fetchNames;
  final Future<void> Function(String appointmentId, String status) onUpdateStatus;
  final Future<void> Function(String appointmentId, String? currentNotes) onAddNotes;

  const _DoctorAppointmentsModule({
    required this.doctorId,
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.fetchNames,
    required this.onUpdateStatus,
    required this.onAddNotes,
  });

  @override
  Widget build(BuildContext context) {
    const statusOptions = [
      'all',
      'pending',
      'confirmed',
      'completed',
      'cancelled',
      'no_show',
      'accepted',
      'rejected',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointments management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirm, cancel, and complete appointments.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onQueryChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search by patient name',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: statusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (value) => onStatusChanged(value ?? 'all'),
                    ),
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
                  .collection('appointments')
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load appointments'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No appointments found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  if (statusFilter != 'all' && statusFilter != status) continue;
                  final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                  filtered.add(_AppointmentView(
                    id: doc.id,
                    patientId: (data['userId'] as String?) ?? '',
                    dateTime: dt,
                    status: status,
                    notes: data['notes'] as String?,
                  ));
                }

                filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchNames(filtered.map((e) => e.patientId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    final visible = filtered.where((appt) {
                      if (normalized.isEmpty) return true;
                      final pname = (names[appt.patientId] ?? appt.patientId).toLowerCase();
                      return pname.contains(normalized);
                    }).toList();

                    if (visible.isEmpty) {
                      return const Center(child: Text('No matching appointments'));
                    }

                    return ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = visible[index];
                        final pname = names[appt.patientId] ?? appt.patientId;
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pname,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusPill(
                                    label: appt.status,
                                    active: appt.status == 'confirmed' || appt.status == 'pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatDateTime(appt.dateTime)),
                              if ((appt.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Notes: ${appt.notes}'),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _buildAppointmentActions(appt),
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

  List<Widget> _buildAppointmentActions(_AppointmentView appt) {
    final actions = <Widget>[];

    void addAction(String label, IconData icon, String status) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => onUpdateStatus(appt.id, status),
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    if (appt.status == 'pending') {
      addAction('Confirm', Icons.check_circle_outline, 'confirmed');
      addAction('Cancel', Icons.cancel_outlined, 'cancelled');
    } else if (appt.status == 'confirmed' || appt.status == 'accepted') {
      addAction('Complete', Icons.done_all, 'completed');
      addAction('No show', Icons.person_off_outlined, 'no_show');
      addAction('Cancel', Icons.cancel_outlined, 'cancelled');
    }

    actions.add(
      OutlinedButton.icon(
        onPressed: () => onAddNotes(appt.id, appt.notes),
        icon: const Icon(Icons.notes_outlined),
        label: const Text('Notes'),
      ),
    );

    return actions;
  }
}
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
          stream: FirebaseFirestore.instance.collection('doctors').doc(doctorId).snapshots(),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Define working hours, slot length, and break times.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text('Working days', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                          decoration: const InputDecoration(labelText: 'Start time (HH:MM)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(labelText: 'End time (HH:MM)'),
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
                          decoration: const InputDecoration(labelText: 'Slot duration (minutes)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: breakStartController,
                          decoration: const InputDecoration(labelText: 'Break start (optional)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: breakEndController,
                          decoration: const InputDecoration(labelText: 'Break end (optional)'),
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
                        label: Text(isGenerating ? 'Generating...' : 'Generate next 14 days'),
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
                  return const Center(child: Text('Failed to load availability')); 
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No upcoming slots'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final start = _parseDate(data['startTime']);
                    final end = _parseDate(data['endTime']);
                    final isBooked = (data['isBooked'] as bool?) ?? false;
                    final blocked = (data['blockedReason'] as String?) != null;
                    final label = blocked ? 'Blocked' : (isBooked ? 'Booked' : 'Available');

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${_formatDateTime(start)} - ${_formatTime(end)}')),
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
class _DoctorPatientsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<Map<String, _UserDetails>> Function(Set<String> ids) fetchUserDetails;
  final Future<void> Function(String patientId, String patientName) onViewHistory;

  const _DoctorPatientsModule({
    required this.doctorId,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.fetchUserDetails,
    required this.onViewHistory,
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
                'Patients',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Patients who have booked with you.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search patient name',
                  prefixIcon: Icon(Icons.search),
                ),
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
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load patients'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No patients yet'));
                }

                final patientMap = <String, _PatientSummary>{};
                for (final doc in docs) {
                  final data = doc.data();
                  final patientId = (data['userId'] as String?) ?? '';
                  if (patientId.isEmpty) continue;
                  final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                  final summary = patientMap[patientId];
                  if (summary == null) {
                    patientMap[patientId] = _PatientSummary(id: patientId, lastVisit: dt, count: 1);
                  } else {
                    final last = dt.isAfter(summary.lastVisit) ? dt : summary.lastVisit;
                    patientMap[patientId] = _PatientSummary(
                      id: patientId,
                      lastVisit: last,
                      count: summary.count + 1,
                    );
                  }
                }

                final patientIds = patientMap.keys.toSet();
                return FutureBuilder<Map<String, _UserDetails>>(
                  future: fetchUserDetails(patientIds),
                  builder: (context, snap) {
                    final details = snap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final list = patientMap.values.where((p) {
                      if (normalized.isEmpty) return true;
                      final name = (details[p.id]?.name ?? p.id).toLowerCase();
                      return name.contains(normalized);
                    }).toList();

                    if (list.isEmpty) {
                      return const Center(child: Text('No matching patients'));
                    }

                    list.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final info = details[item.id];
                        final name = info?.name ?? item.id;
                        final email = info?.email ?? '';
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(child: Icon(Icons.person)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (email.isNotEmpty)
                                          Text(
                                            email,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _StatusPill(label: '${item.count} visits', active: true),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Last visit: ${_formatDateTime(item.lastVisit)}'),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => onViewHistory(item.id, name),
                                icon: const Icon(Icons.history),
                                label: const Text('History'),
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
}
class _DoctorProfileSettingsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController nameController;
  final TextEditingController specialtyController;
  final TextEditingController bioController;
  final TextEditingController experienceController;
  final TextEditingController feeController;
  final TextEditingController imageController;
  final TextEditingController contactEmailController;
  final TextEditingController contactPhoneController;
  final VoidCallback onSaveProfile;
  final void Function(Map<String, dynamic>? data) onLoadProfile;
  final bool profileLoaded;
  final ValueChanged<bool> setProfileLoaded;

  const _DoctorProfileSettingsModule({
    required this.doctorId,
    required this.nameController,
    required this.specialtyController,
    required this.bioController,
    required this.experienceController,
    required this.feeController,
    required this.imageController,
    required this.contactEmailController,
    required this.contactPhoneController,
    required this.onSaveProfile,
    required this.onLoadProfile,
    required this.profileLoaded,
    required this.setProfileLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('doctors').doc(doctorId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load profile: ${snapshot.error}'));
        }
        if (snapshot.hasData && !profileLoaded) {
          onLoadProfile(snapshot.data?.data());
          setProfileLoaded(true);
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
                      'Profile settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep your professional data accurate.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specialtyController,
                      decoration: const InputDecoration(labelText: 'Specialty'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Experience (years)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Consultation fee'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Profile image URL'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactEmailController,
                      decoration: const InputDecoration(labelText: 'Contact email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Contact phone'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: onSaveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
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
      workingDays: (map['workingDays'] as List?)?.map((e) => e as int).toList() ?? [1, 2, 3, 4, 5],
      startTime: (map['startTime'] as String?) ?? '09:00',
      endTime: (map['endTime'] as String?) ?? '17:00',
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      breakStart: map['breakStart'] as String?,
      breakEnd: map['breakEnd'] as String?,
      blockedDates: (map['blockedDates'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

DateTime _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
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

DateTime _weekStart(DateTime dt) {
  final day = DateTime(dt.year, dt.month, dt.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

List<String> _parseBlockedDates(String input) {
  return input
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.length == 10)
      .toSet()
      .toList();
}
