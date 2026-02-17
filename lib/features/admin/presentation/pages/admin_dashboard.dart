// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/services/appointment_policy_service.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/core/widgets/user_theme_toggle_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'admin_dashboard_shared.dart';
part 'admin_dashboard_overview_module.dart';
part 'admin_dashboard_doctor_management_module.dart';
part 'admin_dashboard_user_management_module.dart';
part 'admin_dashboard_appointment_oversight_module.dart';
part 'admin_dashboard_reports_module.dart';
part 'admin_dashboard_basic_settings_module.dart';
part 'admin_dashboard_settings_module.dart';
part 'admin_dashboard_models.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _navItems = const [
    _AdminNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _AdminNavItem(label: 'Doctors', icon: Icons.medical_services_outlined),
    _AdminNavItem(label: 'Users', icon: Icons.people_outline),
    _AdminNavItem(label: 'Appointments', icon: Icons.event_note_outlined),
    _AdminNavItem(label: 'Reports', icon: Icons.insights_outlined),
    _AdminNavItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 0;

  final TextEditingController _doctorSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _appointmentSearchController =
      TextEditingController();

  String _doctorQuery = '';
  String _userQuery = '';
  String _appointmentQuery = '';
  String? _appointmentDoctorId;
  DateTimeRange? _appointmentRange;

  late Future<_AdminDashboardMetrics> _metricsFuture;
  late Future<_AdminReportsData> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadDashboardMetrics();
    _reportsFuture = _loadReports();
  }

  @override
  void dispose() {
    _doctorSearchController.dispose();
    _userSearchController.dispose();
    _appointmentSearchController.dispose();
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

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  } else if (_selectedIndex == 4) {
                    _refreshReports();
                  } else {
                    setState(() {});
                  }
                },
              ),
              const UserThemeToggleButton(),
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
          drawer: isWide
              ? null
              : Drawer(child: _buildSidebar(context, inDrawer: true)),
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
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                _QuickActionChip(
                                  label: 'New report',
                                  icon: Icons.auto_graph_outlined,
                                  onTap: () => _selectModule(4),
                                ),
                                const SizedBox(width: 10),
                                _QuickActionChip(
                                  label: 'Manage users',
                                  icon: Icons.people_alt_outlined,
                                  onTap: () => _selectModule(2),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _safeBuildModule(context),
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
                child: Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Console',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System operations',
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
    switch (_selectedIndex) {
      case 0:
        return _DashboardModule(
          metricsFuture: _metricsFuture,
          onRefresh: _refreshDashboard,
        );
      case 1:
        return _DoctorManagementModule(
          searchController: _doctorSearchController,
          query: _doctorQuery,
          onQueryChanged: (value) => setState(() => _doctorQuery = value),
          onApprove: _setDoctorActive,
          onSuspend: _setDoctorActive,
          onEdit: _editDoctorProfile,
          onViewAvailability: _showDoctorAvailability,
          onViewAppointments: _showDoctorAppointments,
        );
      case 2:
        return _UserManagementModule(
          searchController: _userSearchController,
          query: _userQuery,
          onQueryChanged: (value) => setState(() => _userQuery = value),
          onSetRole: _setRole,
          onSetStatus: _setStatus,
          onViewHistory: _showUserAppointments,
        );
      case 3:
        return _AppointmentOversightModule(
          searchController: _appointmentSearchController,
          query: _appointmentQuery,
          doctorFilterId: _appointmentDoctorId,
          range: _appointmentRange,
          onQueryChanged: (value) => setState(() => _appointmentQuery = value),
          onDoctorChanged: (value) =>
              setState(() => _appointmentDoctorId = value),
          onRangeChanged: (range) => setState(() => _appointmentRange = range),
        );
      case 4:
        return _ReportsModule(
          reportsFuture: _reportsFuture,
          onRefresh: _refreshReports,
        );
      case 5:
        return const _BasicSettingsModule();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _setDoctorActive(String doctorId, bool active) async {
    final db = FirebaseFirestore.instance;
    final now = FieldValue.serverTimestamp();
    try {
      await db.runTransaction((tx) async {
        final userRef = db.collection('users').doc(doctorId);
        final doctorRef = db.collection('doctors').doc(doctorId);
        tx.set(userRef, {
          'role': 'doctor',
          'status': active ? 'active' : 'suspended',
          'isAdmin': false,
          'updatedAt': now,
        }, SetOptions(merge: true));
        tx.set(doctorRef, {
          'isActive': active,
          'updatedAt': now,
        }, SetOptions(merge: true));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Doctor approved' : 'Doctor suspended'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update doctor: $e')));
    }
  }

  Future<void> _editDoctorProfile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final nameController = TextEditingController(
      text: data['name'] as String? ?? '',
    );
    final specialtyController = TextEditingController(
      text: data['specialty'] as String? ?? '',
    );
    final bioController = TextEditingController(
      text: data['bio'] as String? ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit doctor profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(labelText: 'Specialty'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      specialtyController.dispose();
      bioController.dispose();
      return;
    }

    final db = FirebaseFirestore.instance;
    final now = FieldValue.serverTimestamp();
    try {
      await db.runTransaction((tx) async {
        final doctorRef = db.collection('doctors').doc(doc.id);
        final userRef = db.collection('users').doc(doc.id);
        tx.set(doctorRef, {
          'name': nameController.text.trim(),
          'specialty': specialtyController.text.trim(),
          'bio': bioController.text.trim(),
          'updatedAt': now,
        }, SetOptions(merge: true));
        if (nameController.text.trim().isNotEmpty) {
          tx.set(userRef, {
            'displayName': nameController.text.trim(),
            'updatedAt': now,
          }, SetOptions(merge: true));
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doctor updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update doctor: $e')));
    } finally {
      nameController.dispose();
      specialtyController.dispose();
      bioController.dispose();
    }
  }

  Future<void> _showDoctorAvailability(
    BuildContext context,
    String doctorId,
    String doctorName,
  ) async {
    final db = FirebaseFirestore.instance;
    final slotsSnap = await db
        .collection('availability')
        .doc(doctorId)
        .collection('slots')
        .orderBy('startTime')
        .limit(20)
        .get();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Availability: $doctorName'),
          content: SizedBox(
            width: 420,
            child: slotsSnap.docs.isEmpty
                ? const Text('No availability slots found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final data = slotsSnap.docs[index].data();
                      final start = _parseDate(data['startTime']);
                      final end = _parseDate(data['endTime']);
                      final booked = (data['isBooked'] as bool?) ?? false;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          booked ? Icons.lock : Icons.lock_open,
                          size: 18,
                        ),
                        title: Text(
                          '${_formatDateTime(start)} - ${_formatTime(end)}',
                        ),
                        subtitle: Text(booked ? 'Booked' : 'Available'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: slotsSnap.docs.length,
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

  Future<void> _showDoctorAppointments(
    BuildContext context,
    String doctorId,
    String doctorName,
  ) async {
    final db = FirebaseFirestore.instance;
    final appts = await db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentTime', descending: true)
        .limit(15)
        .get();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Appointments: $doctorName'),
          content: SizedBox(
            width: 440,
            child: appts.docs.isEmpty
                ? const Text('No appointments found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final data = appts.docs[index].data();
                      final dt = _parseDate(
                        data['appointmentTime'] ?? data['dateTime'],
                      );
                      final status = (data['status'] as String?) ?? 'pending';
                      return ListTile(
                        dense: true,
                        title: Text(_formatDateTime(dt)),
                        subtitle: Text('Status: $status'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: appts.docs.length,
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

  Future<void> _setRole(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String role,
  ) async {
    final db = FirebaseFirestore.instance;
    final uid = doc.id;
    final now = FieldValue.serverTimestamp();
    final userRef = db.collection('users').doc(uid);
    final doctorRef = db.collection('doctors').doc(uid);
    final data = doc.data();

    try {
      await db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final userData = userSnap.data() ?? data;
        final name = (userData['displayName'] as String?) ?? 'Doctor';
        final email = userData['email'] as String?;
        final photoUrl =
            (userData['photoUrl'] as String?) ??
            (userData['avatarUrl'] as String?);

        tx.update(userRef, {
          'role': role,
          'isAdmin': role == 'admin',
          'updatedAt': now,
        });

        if (role == 'doctor') {
          final doctorSnap = await tx.get(doctorRef);
          final doctorData = <String, dynamic>{
            'userId': uid,
            'name': name,
            'specialty':
                (doctorSnap.data()?['specialty'] as String?) ?? 'General',
            'bio': (doctorSnap.data()?['bio'] as String?) ?? '',
            'email': email,
            'photoUrl': photoUrl,
            'avatarUrl': photoUrl,
            'isActive': true,
            'updatedAt': now,
          };
          if (!doctorSnap.exists) doctorData['createdAt'] = now;
          tx.set(doctorRef, doctorData, SetOptions(merge: true));
        } else {
          final doctorSnap = await tx.get(doctorRef);
          if (doctorSnap.exists) {
            tx.update(doctorRef, {'isActive': false, 'updatedAt': now});
          }
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Role updated to $role')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final db = FirebaseFirestore.instance;
    final uid = doc.id;
    final now = FieldValue.serverTimestamp();
    final userRef = db.collection('users').doc(uid);
    final doctorRef = db.collection('doctors').doc(uid);
    final role = (doc.data()['role'] as String?) ?? 'user';

    try {
      await db.runTransaction((tx) async {
        tx.update(userRef, {'status': status, 'updatedAt': now});
        if (role == 'doctor' && status == 'suspended') {
          final doctorSnap = await tx.get(doctorRef);
          if (doctorSnap.exists) {
            tx.update(doctorRef, {'isActive': false, 'updatedAt': now});
          }
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status set to $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _showUserAppointments(
    BuildContext context,
    String userId,
    String label,
  ) async {
    final db = FirebaseFirestore.instance;
    final appts = await db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('appointmentTime', descending: true)
        .limit(20)
        .get();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Appointment history: $label'),
          content: SizedBox(
            width: 440,
            child: appts.docs.isEmpty
                ? const Text('No appointments found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final data = appts.docs[index].data();
                      final dt = _parseDate(
                        data['appointmentTime'] ?? data['dateTime'],
                      );
                      final status = (data['status'] as String?) ?? 'pending';
                      return ListTile(
                        dense: true,
                        title: Text(_formatDateTime(dt)),
                        subtitle: Text('Status: $status'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: appts.docs.length,
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

  Future<_AdminDashboardMetrics> _loadDashboardMetrics() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final usersFuture = db.collection('users').get();
    final doctorsFuture = db.collection('doctors').get();
    final todayApptsFuture = db
        .collection('appointments')
        .where(
          'appointmentTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('appointmentTime', isLessThan: Timestamp.fromDate(end))
        .get();
    final completedFuture = db
        .collection('appointments')
        .where('status', isEqualTo: 'completed')
        .get();
    final activeFuture = db
        .collection('appointments')
        .where('status', whereIn: ['pending', 'confirmed', 'accepted'])
        .get();
    final pendingDoctorsFuture = db
        .collection('doctors')
        .where('isActive', isEqualTo: false)
        .get();

    final results = await Future.wait([
      usersFuture,
      doctorsFuture,
      todayApptsFuture,
      completedFuture,
      activeFuture,
      pendingDoctorsFuture,
    ]);

    return _AdminDashboardMetrics(
      totalUsers: results[0].docs.length,
      totalDoctors: results[1].docs.length,
      appointmentsToday: results[2].docs.length,
      completedAppointments: results[3].docs.length,
      activeAppointments: results[4].docs.length,
      pendingApprovals: results[5].docs.length,
    );
  }

  Future<_AdminReportsData> _loadReports() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final start30 = now.subtract(const Duration(days: 30));
    final start7 = now.subtract(const Duration(days: 7));
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final utilizationEnd = todayStart.add(const Duration(days: 30));

    final apptsSnap = await db
        .collection('appointments')
        .where(
          'appointmentTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start30),
        )
        .get();

    final appointments = apptsSnap.docs.map((d) => d.data()).toList();
    final perDay = <String, int>{};
    final dayOrder = <String>[];
    for (var i = 6; i >= 0; i -= 1) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final key = _formatDay(day);
      perDay[key] = 0;
      dayOrder.add(key);
    }

    final doctorCounts = <String, int>{};
    final userSet = <String>{};
    final bookingStatus = <String, int>{
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };
    var appointmentsToday = 0;
    var cancelled = 0;

    for (final data in appointments) {
      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final status = (data['status'] as String?) ?? 'pending';
      final doctorId = (data['doctorId'] as String?) ?? '';
      final userId = (data['userId'] as String?) ?? '';

      if (dt.isAfter(start7)) {
        userSet.add(userId);
      }
      if (!dt.isBefore(todayStart) && dt.isBefore(tomorrow)) {
        appointmentsToday += 1;
      }
      if (status == 'cancelled') cancelled += 1;
      if (doctorId.isNotEmpty) {
        doctorCounts[doctorId] = (doctorCounts[doctorId] ?? 0) + 1;
      }
      if (status == 'pending') {
        bookingStatus['pending'] = (bookingStatus['pending'] ?? 0) + 1;
      } else if (status == 'confirmed' || status == 'accepted') {
        bookingStatus['confirmed'] = (bookingStatus['confirmed'] ?? 0) + 1;
      } else if (status == 'completed') {
        bookingStatus['completed'] = (bookingStatus['completed'] ?? 0) + 1;
      } else if (status == 'cancelled') {
        bookingStatus['cancelled'] = (bookingStatus['cancelled'] ?? 0) + 1;
      }

      final key = _formatDay(DateTime(dt.year, dt.month, dt.day));
      if (perDay.containsKey(key)) {
        perDay[key] = (perDay[key] ?? 0) + 1;
      }
    }

    final total = appointments.length;
    final cancelRate = total == 0 ? 0.0 : (cancelled / total);
    final topDoctors = doctorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDoctorIds = topDoctors.take(3).map((e) => e.key).toList();
    final doctorNames = await _prefetchDoctorNames(topDoctorIds);
    var totalSlots = 0;
    var bookedSlots = 0;

    Future<QuerySnapshot<Map<String, dynamic>>?> fetchDoctorSlots(
      String doctorId,
    ) async {
      try {
        return await db
            .collection('availability')
            .doc(doctorId)
            .collection('slots')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .where('startTime', isLessThan: Timestamp.fromDate(utilizationEnd))
            .get();
      } catch (_) {
        return null;
      }
    }

    try {
      final doctorsSnap = await db.collection('doctors').get();
      final slotSnaps = await Future.wait(
        doctorsSnap.docs.map((doc) => fetchDoctorSlots(doc.id)),
      );
      for (final slotsSnap in slotSnaps) {
        if (slotsSnap == null) continue;
        totalSlots += slotsSnap.docs.length;
        for (final slotDoc in slotsSnap.docs) {
          final data = slotDoc.data();
          final isBooked = (data['isBooked'] as bool?) ?? false;
          if (isBooked) bookedSlots += 1;
        }
      }
    } catch (_) {
      // Keep report resilient if utilization data cannot be fetched.
    }

    final doctorUtilizationRate = totalSlots == 0
        ? 0.0
        : bookedSlots / totalSlots;
    var pendingNotificationEvents = 0;
    var pendingModerationEvents = 0;
    var appliedModerationEvents = 0;

    try {
      final pendingNotificationsSnap = await db
          .collection('notification_events')
          .where('status', isEqualTo: 'pending')
          .get();
      pendingNotificationEvents = pendingNotificationsSnap.docs.length;
    } catch (_) {
      pendingNotificationEvents = 0;
    }

    try {
      final pendingModerationSnap = await db
          .collection('moderation_events')
          .where('status', isEqualTo: 'pending_review')
          .get();
      pendingModerationEvents = pendingModerationSnap.docs.length;
    } catch (_) {
      pendingModerationEvents = 0;
    }

    try {
      final appliedModerationSnap = await db
          .collection('moderation_events')
          .where('status', isEqualTo: 'applied')
          .get();
      appliedModerationEvents = appliedModerationSnap.docs.length;
    } catch (_) {
      appliedModerationEvents = 0;
    }

    return _AdminReportsData(
      appointmentsPerDay: dayOrder
          .map((key) => _ReportPoint(label: key, value: perDay[key] ?? 0))
          .toList(),
      mostBookedDoctors: topDoctors.take(3).map((e) {
        return _ReportPoint(label: doctorNames[e.key] ?? e.key, value: e.value);
      }).toList(),
      bookingStatusBreakdown: [
        _ReportPoint(label: 'pending', value: bookingStatus['pending'] ?? 0),
        _ReportPoint(
          label: 'confirmed',
          value: bookingStatus['confirmed'] ?? 0,
        ),
        _ReportPoint(
          label: 'completed',
          value: bookingStatus['completed'] ?? 0,
        ),
        _ReportPoint(
          label: 'cancelled',
          value: bookingStatus['cancelled'] ?? 0,
        ),
      ],
      appointmentsToday: appointmentsToday,
      bookedSlots: bookedSlots,
      totalSlots: totalSlots,
      doctorUtilizationRate: doctorUtilizationRate,
      cancellationRate: cancelRate,
      activeUsersWeekly: userSet.length,
      pendingNotificationEvents: pendingNotificationEvents,
      pendingModerationEvents: pendingModerationEvents,
      appliedModerationEvents: appliedModerationEvents,
    );
  }

  Widget _safeBuildModule(BuildContext context) {
    try {
      return _buildModule(context);
    } catch (e) {
      return Center(
        child: AppCard(
          child: Text(
            'Module failed to render: $e',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}





