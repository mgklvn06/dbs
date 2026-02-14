// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _appointmentSearchController = TextEditingController();

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
                child: Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Console',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
          onDoctorChanged: (value) => setState(() => _appointmentDoctorId = value),
          onRangeChanged: (range) => setState(() => _appointmentRange = range),
        );
      case 4:
        return _ReportsModule(
          reportsFuture: _reportsFuture,
          onRefresh: _refreshReports,
        );
      case 5:
        return const _SettingsModule();
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
        tx.set(
          userRef,
          {
            'role': 'doctor',
            'status': active ? 'active' : 'suspended',
            'isAdmin': false,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
        tx.set(
          doctorRef,
          {
            'isActive': active,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(active ? 'Doctor approved' : 'Doctor suspended')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update doctor: $e')),
      );
    }
  }
  Future<void> _editDoctorProfile(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final nameController = TextEditingController(text: data['name'] as String? ?? '');
    final specialtyController = TextEditingController(text: data['specialty'] as String? ?? '');
    final bioController = TextEditingController(text: data['bio'] as String? ?? '');

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
        tx.set(
          doctorRef,
          {
            'name': nameController.text.trim(),
            'specialty': specialtyController.text.trim(),
            'bio': bioController.text.trim(),
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
        if (nameController.text.trim().isNotEmpty) {
          tx.set(
            userRef,
            {
              'displayName': nameController.text.trim(),
              'updatedAt': now,
            },
            SetOptions(merge: true),
          );
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update doctor: $e')));
    } finally {
      nameController.dispose();
      specialtyController.dispose();
      bioController.dispose();
    }
  }

  Future<void> _showDoctorAvailability(BuildContext context, String doctorId, String doctorName) async {
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
                        leading: Icon(booked ? Icons.lock : Icons.lock_open, size: 18),
                        title: Text('${_formatDateTime(start)} - ${_formatTime(end)}'),
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

  Future<void> _showDoctorAppointments(BuildContext context, String doctorId, String doctorName) async {
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
                      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
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
        final photoUrl = (userData['photoUrl'] as String?) ?? (userData['avatarUrl'] as String?);

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
            'specialty': (doctorSnap.data()?['specialty'] as String?) ?? 'General',
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $role')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _showUserAppointments(BuildContext context, String userId, String label) async {
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
                      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
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
        .where('appointmentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('appointmentTime', isLessThan: Timestamp.fromDate(end))
        .get();
    final completedFuture = db.collection('appointments').where('status', isEqualTo: 'completed').get();
    final activeFuture = db.collection('appointments').where('status', whereIn: ['pending', 'confirmed', 'accepted']).get();
    final pendingDoctorsFuture = db.collection('doctors').where('isActive', isEqualTo: false).get();

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

    final apptsSnap = await db
        .collection('appointments')
        .where('appointmentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start30))
        .get();

    final appointments = apptsSnap.docs.map((d) => d.data()).toList();
    final perDay = <String, int>{};
    final dayOrder = <String>[];
    for (var i = 6; i >= 0; i -= 1) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = _formatDay(day);
      perDay[key] = 0;
      dayOrder.add(key);
    }

    final doctorCounts = <String, int>{};
    final userSet = <String>{};
    var cancelled = 0;

    for (final data in appointments) {
      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final status = (data['status'] as String?) ?? 'pending';
      final doctorId = (data['doctorId'] as String?) ?? '';
      final userId = (data['userId'] as String?) ?? '';

      if (dt.isAfter(start7)) {
        userSet.add(userId);
      }
      if (status == 'cancelled') cancelled += 1;
      if (doctorId.isNotEmpty) {
        doctorCounts[doctorId] = (doctorCounts[doctorId] ?? 0) + 1;
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

    return _AdminReportsData(
      appointmentsPerDay: dayOrder.map((key) => _ReportPoint(label: key, value: perDay[key] ?? 0)).toList(),
      mostBookedDoctors: topDoctors.take(3).map((e) {
        return _ReportPoint(label: doctorNames[e.key] ?? e.key, value: e.value);
      }).toList(),
      cancellationRate: cancelRate,
      activeUsersWeekly: userSet.length,
    );
  }
}
class _AdminNavItem {
  final String label;
  final IconData icon;

  const _AdminNavItem({required this.label, required this.icon});
}

class _NavTile extends StatelessWidget {
  final _AdminNavItem item;
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

class _DashboardModule extends StatelessWidget {
  final Future<_AdminDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;

  const _DashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminDashboardMetrics>(
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
                delay: const Duration(milliseconds: 50),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'System snapshot',
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
                          _MetricCard(title: 'Total users', value: data.totalUsers.toString()),
                          _MetricCard(title: 'Total doctors', value: data.totalDoctors.toString()),
                          _MetricCard(title: 'Appointments today', value: data.appointmentsToday.toString()),
                          _MetricCard(title: 'Active appointments', value: data.activeAppointments.toString()),
                          _MetricCard(title: 'Completed appointments', value: data.completedAppointments.toString()),
                          _MetricCard(title: 'Pending approvals', value: data.pendingApprovals.toString()),
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
                      'Quick actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _ActionChip(label: 'Approve doctors', icon: Icons.verified_user_outlined),
                        _ActionChip(label: 'Review appointments', icon: Icons.event_available_outlined),
                        _ActionChip(label: 'Audit users', icon: Icons.people_alt_outlined),
                      ],
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
class _DoctorManagementModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(String doctorId, bool active) onApprove;
  final Future<void> Function(String doctorId, bool active) onSuspend;
  final Future<void> Function(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) onEdit;
  final Future<void> Function(BuildContext context, String doctorId, String doctorName) onViewAvailability;
  final Future<void> Function(BuildContext context, String doctorId, String doctorName) onViewAppointments;

  const _DoctorManagementModule({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onApprove,
    required this.onSuspend,
    required this.onEdit,
    required this.onViewAvailability,
    required this.onViewAppointments,
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
                'Doctor management',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Approve, suspend, and review doctor activity.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or specialty',
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
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load doctors'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No doctors found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = normalized.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final name = (data['name'] as String?) ?? '';
                        final spec = (data['specialty'] as String?) ?? '';
                        return name.toLowerCase().contains(normalized) || spec.toLowerCase().contains(normalized);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching doctors'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final name = (data['name'] as String?) ?? 'Doctor';
                    final specialty = (data['specialty'] as String?) ?? 'General';
                    final email = (data['email'] as String?) ?? 'no-email';
                    final isActive = (data['isActive'] as bool?) ?? false;

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person_outline)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '$specialty | $email',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(label: isActive ? 'Active' : 'Pending', active: isActive),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (!isActive)
                                OutlinedButton.icon(
                                  onPressed: () => onApprove(doc.id, true),
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text('Approve'),
                                ),
                              if (isActive)
                                OutlinedButton.icon(
                                  onPressed: () => onSuspend(doc.id, false),
                                  icon: const Icon(Icons.pause_circle_outline),
                                  label: const Text('Suspend'),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => onEdit(context, doc),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit profile'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => onViewAvailability(context, doc.id, name),
                                icon: const Icon(Icons.schedule_outlined),
                                label: const Text('Availability'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => onViewAppointments(context, doc.id, name),
                                icon: const Icon(Icons.event_available_outlined),
                                label: const Text('Appointments'),
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
          ),
        ),
      ],
    );
  }
}
class _UserManagementModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, String role) onSetRole;
  final Future<void> Function(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, String status) onSetStatus;
  final Future<void> Function(BuildContext context, String userId, String label) onViewHistory;

  const _UserManagementModule({
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onSetRole,
    required this.onSetStatus,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User management',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Review users, suspend access, and update roles.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name or email',
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
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load users'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                final normalized = query.trim().toLowerCase();
                final filtered = normalized.isEmpty
                    ? docs
                    : docs.where((d) {
                        final data = d.data();
                        final name = (data['displayName'] as String?) ?? '';
                        final email = (data['email'] as String?) ?? '';
                        return name.toLowerCase().contains(normalized) || email.toLowerCase().contains(normalized);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching users'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final name = (data['displayName'] as String?) ?? 'Unknown';
                    final email = (data['email'] as String?) ?? 'no-email';
                    final role = (data['role'] as String?) ?? 'user';
                    final status = (data['status'] as String?) ?? 'active';
                    final isSelf = doc.id == currentUser?.uid;

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
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '$email | $role | $status${isSelf ? ' (you)' : ''}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(label: status, active: status == 'active'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => onViewHistory(context, doc.id, name),
                                icon: const Icon(Icons.history),
                                label: const Text('History'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSelf
                                    ? null
                                    : () => _showRoleSheet(context, doc, role, onSetRole),
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text('Change role'),
                              ),
                              OutlinedButton.icon(
                                onPressed: isSelf
                                    ? null
                                    : () => onSetStatus(context, doc, status == 'active' ? 'suspended' : 'active'),
                                icon: const Icon(Icons.pause_circle_outline),
                                label: Text(status == 'active' ? 'Suspend' : 'Activate'),
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
          ),
        ),
      ],
    );
  }

  void _showRoleSheet(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String role,
    Future<void> Function(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, String role) onSetRole,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text((doc.data()['displayName'] as String?) ?? doc.id),
                subtitle: Text('Current role: $role'),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: role != 'user',
                leading: const Icon(Icons.person_outline),
                title: const Text('Set role: user'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'user');
                },
              ),
              ListTile(
                enabled: role != 'doctor',
                leading: const Icon(Icons.medical_services_outlined),
                title: const Text('Set role: doctor'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'doctor');
                },
              ),
              ListTile(
                enabled: role != 'admin',
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Set role: admin'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onSetRole(context, doc, 'admin');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                                label: Text(range == null ? 'Filter by date' : _formatRange(range!)),
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
                        label: Text(range == null ? 'Filter by date' : _formatRange(range!)),
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
                  return const Center(child: Text('Failed to load appointments'));
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
                      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                      final matchDoctor = doctorFilterId == null || doctorFilterId == doctorId;
                      final matchRange = range == null || (dt.isAfter(range!.start.subtract(const Duration(seconds: 1))) && dt.isBefore(range!.end.add(const Duration(days: 1))));
                      if (!matchDoctor || !matchRange) return false;
                      if (normalized.isEmpty) return true;
                      final userName = (users[userId] ?? userId).toLowerCase();
                      final doctorName = (doctors[doctorId] ?? doctorId).toLowerCase();
                      return userName.contains(normalized) || doctorName.contains(normalized) || userId.contains(normalized) || doctorId.contains(normalized);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No matching appointments'));
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data = doc.data();
                        final userId = (data['userId'] as String?) ?? '';
                        final doctorId = (data['doctorId'] as String?) ?? '';
                        final status = (data['status'] as String?) ?? 'pending';
                        final disputed = (data['disputed'] as bool?) ?? false;
                        final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
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
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  _StatusPill(label: status, active: status == 'confirmed' || status == 'accepted' || status == 'pending'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_formatDateTime(dt)} | ${disputed ? 'Disputed' : 'Normal'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _updateAppointmentStatus(doc.id, 'cancelled'),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _toggleDispute(doc.id, !disputed),
                                    icon: Icon(disputed ? Icons.flag_outlined : Icons.flag),
                                    label: Text(disputed ? 'Clear dispute' : 'Mark dispute'),
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleDispute(String id, bool disputed) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({
      'disputed': disputed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, Map<String, String>>> _prefetchNames(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
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
        final q = await firestore.collection('users').where(FieldPath.documentId, whereIn: slice).get();
        for (var d in q.docs) {
          final data = d.data();
          users[d.id] = (data['displayName'] as String?) ?? (data['email'] as String?) ?? d.id;
        }
      }
    }

    Future<void> fetchDoctors() async {
      final ids = doctorIds.where((e) => e.isNotEmpty).toList();
      const chunk = 10;
      for (var i = 0; i < ids.length; i += chunk) {
        final slice = ids.sublist(i, min(i + chunk, ids.length));
        final q = await firestore.collection('doctors').where(FieldPath.documentId, whereIn: slice).get();
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
class _ReportsModule extends StatelessWidget {
  final Future<_AdminReportsData> reportsFuture;
  final VoidCallback onRefresh;

  const _ReportsModule({
    required this.reportsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminReportsData>(
      future: reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load reports: ${snapshot.error}'));
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
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
                      'Appointments per day (7 days)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                          'Most booked doctors',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _RankList(points: data.mostBookedDoctors),
                      ],
                    ),
                  );
                  final rightCard = AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancellation rate',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(data.cancellationRate * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Active users (7 days)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.activeUsersWeekly.toString(),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
            ],
          ),
        );
      },
    );
  }
}

class _SettingsModule extends StatefulWidget {
  const _SettingsModule();

  @override
  State<_SettingsModule> createState() => _SettingsModuleState();
}

class _SettingsModuleState extends State<_SettingsModule> {
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsRef = FirebaseFirestore.instance.collection('settings').doc('system');
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
        final data = snapshot.data?.data() ?? {};
        final maintenanceMode = (data['maintenanceMode'] as bool?) ?? false;
        final allowNewDoctors = (data['allowNewDoctors'] as bool?) ?? true;
        final limit = (data['bookingLimitPerDay'] as num?)?.toInt();
        final limitText = limit?.toString() ?? '';
        if (_limitController.text != limitText) {
          _limitController.text = limitText;
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
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                      value: maintenanceMode,
                      onChanged: (value) async {
                        try {
                          await settingsRef.set(
                            {
                              'maintenanceMode': value,
                              'updatedAt': FieldValue.serverTimestamp(),
                            },
                            SetOptions(merge: true),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update setting: $e')),
                          );
                        }
                      },
                      title: const Text('Maintenance mode'),
                      subtitle: const Text('Disable booking and sign-ins for non-admin users'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: allowNewDoctors,
                      onChanged: (value) async {
                        try {
                          await settingsRef.set(
                            {
                              'allowNewDoctors': value,
                              'updatedAt': FieldValue.serverTimestamp(),
                            },
                            SetOptions(merge: true),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update setting: $e')),
                          );
                        }
                      },
                      title: const Text('Allow new doctors'),
                      subtitle: const Text('Permit doctors to create profiles and submit availability'),
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
                      'Global booking limits',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max appointments per day (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final raw = _limitController.text.trim();
                          final parsed = int.tryParse(raw);
                          try {
                            await settingsRef.set(
                              {
                                'bookingLimitPerDay': parsed,
                                'updatedAt': FieldValue.serverTimestamp(),
                              },
                              SetOptions(merge: true),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings saved')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to save settings: $e')),
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
            ],
          ),
        );
      },
    );
  }
}
class _DoctorFilter extends StatelessWidget {
  final String? selectedDoctorId;
  final ValueChanged<String?> onChanged;

  const _DoctorFilter({
    required this.selectedDoctorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem(value: null, child: Text('All doctors')),
          ...docs.map((d) {
            final data = d.data();
            final name = (data['name'] as String?) ?? d.id;
            return DropdownMenuItem(value: d.id, child: Text(name));
          }),
        ];
        return DropdownButtonFormField<String?>(
          value: selectedDoctorId,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            labelText: 'Filter by doctor',
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _BarList extends StatelessWidget {
  final List<_ReportPoint> points;

  const _BarList({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty ? 1 : points.map((e) => e.value).reduce(max);
    return Column(
      children: points.map((p) {
        final ratio = maxValue == 0 ? 0.0 : p.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(p.label)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('${p.value}')),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RankList extends StatelessWidget {
  final List<_ReportPoint> points;

  const _RankList({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('No data yet');
    }
    return Column(
      children: points.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(p.label)),
              Text('${p.value}'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

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
  final double cancellationRate;
  final int activeUsersWeekly;

  const _AdminReportsData({
    required this.appointmentsPerDay,
    required this.mostBookedDoctors,
    required this.cancellationRate,
    required this.activeUsersWeekly,
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

String _formatRange(DateTimeRange range) {
  final start = _formatDay(range.start);
  final end = _formatDay(range.end);
  return '$start - $end';
}

Future<Map<String, String>> _prefetchDoctorNames(List<String> ids) async {
  if (ids.isEmpty) return {};
  final firestore = FirebaseFirestore.instance;
  final result = <String, String>{};
  const chunk = 10;
  for (var i = 0; i < ids.length; i += chunk) {
    final slice = ids.sublist(i, min(i + chunk, ids.length));
    final q = await firestore.collection('doctors').where(FieldPath.documentId, whereIn: slice).get();
    for (var d in q.docs) {
      final data = d.data();
      result[d.id] = (data['name'] as String?) ?? d.id;
    }
  }
  return result;
}
