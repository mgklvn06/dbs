
// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final _navItems = const [
    _PatientNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _PatientNavItem(label: 'Find Doctors', icon: Icons.search_outlined),
    _PatientNavItem(label: 'My Appointments', icon: Icons.event_note_outlined),
    _PatientNavItem(label: 'Medical History', icon: Icons.history),
    _PatientNavItem(label: 'Profile Settings', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 0;

  final TextEditingController _doctorSearchController = TextEditingController();
  final TextEditingController _appointmentSearchController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  final TextEditingController _profileAddressController = TextEditingController();
  final TextEditingController _profileDobController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();

  String _doctorQuery = '';
  bool _onlyAvailable = false;
  String _specialtyFilter = 'All';

  String _appointmentQuery = '';
  String _appointmentStatus = 'all';

  bool _profileLoaded = false;
  late Future<_PatientDashboardMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadDashboardMetrics();
  }

  @override
  void dispose() {
    _doctorSearchController.dispose();
    _appointmentSearchController.dispose();
    _profileNameController.dispose();
    _profilePhoneController.dispose();
    _profileAddressController.dispose();
    _profileDobController.dispose();
    _profilePhotoController.dispose();
    super.dispose();
  }

  String? _currentUserId() => FirebaseAuth.instance.currentUser?.uid;

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
                  Navigator.pushReplacementNamed(context, Routes.landing);
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
                                  label: 'Find doctors',
                                  icon: Icons.search,
                                  onTap: () => _selectModule(1),
                                ),
                                const SizedBox(width: 10),
                                _QuickActionChip(
                                  label: 'My appointments',
                                  icon: Icons.event_note_outlined,
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
                child: Icon(Icons.favorite_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Console',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your health, organized',
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
              Navigator.pushReplacementNamed(context, Routes.landing);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildModule(BuildContext context) {
    final userId = _currentUserId();
    if (userId == null) {
      return const _EmptyStateCard(message: 'Session not available.');
    }

    switch (_selectedIndex) {
      case 0:
        return _PatientDashboardModule(
          metricsFuture: _metricsFuture,
          onRefresh: _refreshDashboard,
          fetchDoctorNames: _prefetchDoctorNames,
        );
      case 1:
        return _FindDoctorsModule(
          searchController: _doctorSearchController,
          query: _doctorQuery,
          specialtyFilter: _specialtyFilter,
          onlyAvailable: _onlyAvailable,
          onQueryChanged: (value) => setState(() => _doctorQuery = value),
          onSpecialtyChanged: (value) => setState(() => _specialtyFilter = value),
          onAvailabilityChanged: (value) => setState(() => _onlyAvailable = value),
          onBookDoctor: (doctor) => _handleBookDoctor(context, doctor),
          onViewDoctor: (doc) => _showDoctorDetails(context, doc),
        );
      case 2:
        return _PatientAppointmentsModule(
          userId: userId,
          searchController: _appointmentSearchController,
          query: _appointmentQuery,
          statusFilter: _appointmentStatus,
          onQueryChanged: (value) => setState(() => _appointmentQuery = value),
          onStatusChanged: (value) => setState(() => _appointmentStatus = value),
          fetchDoctorNames: _prefetchDoctorNames,
          onCancel: (id) => _cancelAppointment(context, id),
          canCancel: _canCancelAppointment,
        );
      case 3:
        return _MedicalHistoryModule(
          userId: userId,
          fetchDoctorNames: _prefetchDoctorNames,
        );
      case 4:
        return _ProfileSettingsModule(
          userId: userId,
          nameController: _profileNameController,
          phoneController: _profilePhoneController,
          addressController: _profileAddressController,
          dobController: _profileDobController,
          photoController: _profilePhotoController,
          profileLoaded: _profileLoaded,
          onLoadProfile: _loadProfileFields,
          setProfileLoaded: (value) => _profileLoaded = value,
          onSaveProfile: () => _saveProfile(context, userId),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleBookDoctor(BuildContext context, DoctorEntity doctor) {
    Navigator.pushNamed(context, Routes.bookingAppointment, arguments: doctor);
  }
  bool _canCancelAppointment(DateTime dateTime, String status) {
    const cutoffHours = 6;
    if (status != 'pending' && status != 'confirmed' && status != 'accepted') {
      return false;
    }
    final cutoff = DateTime.now().add(const Duration(hours: cutoffHours));
    return dateTime.isAfter(cutoff);
  }

  Future<void> _cancelAppointment(BuildContext context, String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel appointment'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel appointment'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }

  Future<_PatientDashboardMetrics> _loadDashboardMetrics() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const _PatientDashboardMetrics(
        nextAppointment: null,
        upcomingCount: 0,
        pastCount: 0,
        recommendedDoctors: [],
      );
    }

    final db = FirebaseFirestore.instance;
    final apptsSnap = await db.collection('appointments').where('userId', isEqualTo: userId).get();

    final now = DateTime.now();
    _AppointmentView? next;
    var upcoming = 0;
    var past = 0;

    for (final doc in apptsSnap.docs) {
      final data = doc.data();
      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final status = (data['status'] as String?) ?? 'pending';
      final appt = _AppointmentView(
        id: doc.id,
        doctorId: (data['doctorId'] as String?) ?? '',
        dateTime: dt,
        status: status,
      );
      if (dt.isAfter(now)) {
        upcoming += 1;
        if (next == null || dt.isBefore(next.dateTime)) {
          next = appt;
        }
      } else {
        past += 1;
      }
    }

    final doctorsSnap = await db
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .limit(3)
        .get();
    final recommended = doctorsSnap.docs.map((doc) {
      final data = doc.data();
      return _DoctorSummary(
        id: doc.id,
        name: (data['name'] as String?) ?? 'Doctor',
        specialty: (data['specialty'] as String?) ?? 'Specialist',
        imageUrl: data['profileImageUrl'] as String?,
      );
    }).toList();

    return _PatientDashboardMetrics(
      nextAppointment: next,
      upcomingCount: upcoming,
      pastCount: past,
      recommendedDoctors: recommended,
    );
  }

  Future<Map<String, String>> _prefetchDoctorNames(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final doctors = <String, String>{};
    final list = ids.where((id) => id.isNotEmpty).toList();
    const chunk = 10;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, min(i + chunk, list.length));
      final q = await firestore.collection('doctors').where(FieldPath.documentId, whereIn: slice).get();
      for (final doc in q.docs) {
        final data = doc.data();
        doctors[doc.id] = (data['name'] as String?) ?? doc.id;
      }
    }
    return doctors;
  }

  void _loadProfileFields(Map<String, dynamic>? data) {
    if (_profileLoaded || data == null) return;
    _profileNameController.text = (data['displayName'] as String?) ?? '';
    _profilePhoneController.text = (data['phone'] as String?) ?? '';
    _profileAddressController.text = (data['address'] as String?) ?? '';
    _profileDobController.text = (data['dateOfBirth'] as String?) ?? '';
    final photo = (data['photoUrl'] as String?) ?? (data['avatarUrl'] as String?) ?? '';
    _profilePhotoController.text = photo;
    _profileLoaded = true;
  }

  Future<void> _saveProfile(BuildContext context, String userId) async {
    final name = _profileNameController.text.trim();
    final phone = _profilePhoneController.text.trim();
    final address = _profileAddressController.text.trim();
    final dob = _profileDobController.text.trim();
    final photo = _profilePhotoController.text.trim();

    final payload = <String, dynamic>{
      if (name.isNotEmpty) 'displayName': name,
      if (phone.isNotEmpty) 'phone': phone,
      if (address.isNotEmpty) 'address': address,
      if (dob.isNotEmpty) 'dateOfBirth': dob,
      if (photo.isNotEmpty) 'photoUrl': photo,
      if (photo.isNotEmpty) 'avatarUrl': photo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(payload, SetOptions(merge: true));
      if (name.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      }
      if (photo.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(photo);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  Future<void> _showDoctorDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final name = (data['name'] as String?) ?? 'Doctor';
    final specialty = (data['specialty'] as String?) ?? 'Specialist';
    final bio = (data['bio'] as String?) ?? '';
    final fee = data['consultationFee'];
    final experience = data['experienceYears'];
    final imageUrl = data['profileImageUrl'] as String?;

    final slotsSnap = await FirebaseFirestore.instance
        .collection('availability')
        .doc(doc.id)
        .collection('slots')
        .where('isBooked', isEqualTo: false)
        .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startTime')
        .limit(5)
        .get();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Icon(Icons.medical_services_outlined)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(specialty, style: Theme.of(context).textTheme.titleMedium),
                            if (experience != null) Text('Experience: $experience years'),
                            if (fee != null) Text('Fee: $fee'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(bio),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Upcoming availability',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (slotsSnap.docs.isEmpty)
                    const Text('No available slots')
                  else
                    Column(
                      children: slotsSnap.docs.map((slot) {
                        final slotData = slot.data();
                        final start = _parseDate(slotData['startTime']);
                        final end = _parseDate(slotData['endTime']);
                        return ListTile(
                          dense: true,
                          title: Text('${_formatDateTime(start)} - ${_formatTime(end)}'),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleBookDoctor(context, DoctorEntity(id: doc.id, name: name, specialty: specialty));
              },
              child: const Text('Book now'),
            ),
          ],
        );
      },
    );
  }
}
class _PatientNavItem {
  final String label;
  final IconData icon;

  const _PatientNavItem({required this.label, required this.icon});
}

class _NavTile extends StatelessWidget {
  final _PatientNavItem item;
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
class _PatientDashboardModule extends StatelessWidget {
  final Future<_PatientDashboardMetrics> metricsFuture;
  final VoidCallback onRefresh;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;

  const _PatientDashboardModule({
    required this.metricsFuture,
    required this.onRefresh,
    required this.fetchDoctorNames,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PatientDashboardMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        final next = data.nextAppointment;

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
                              'Your overview',
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
                          _MetricCard(title: 'Upcoming', value: data.upcomingCount.toString()),
                          _MetricCard(title: 'Past visits', value: data.pastCount.toString()),
                          _MetricCard(
                            title: 'Next appointment',
                            value: next == null ? 'None' : _formatDateTime(next.dateTime),
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
                      'Next appointment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (next == null)
                      const Text('No upcoming appointments')
                    else
                      FutureBuilder<Map<String, String>>(
                        future: fetchDoctorNames({next.doctorId}),
                        builder: (context, nameSnap) {
                          final names = nameSnap.data ?? {};
                          final doctorName = names[next.doctorId] ?? next.doctorId;
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$doctorName - ${_formatDateTime(next.dateTime)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              _StatusPill(
                                label: next.status,
                                active: next.status == 'confirmed' || next.status == 'pending',
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended doctors',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (data.recommendedDoctors.isEmpty)
                      const Text('No recommendations available')
                    else
                      Column(
                        children: data.recommendedDoctors.map((doc) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: doc.imageUrl != null && doc.imageUrl!.isNotEmpty
                                      ? NetworkImage(doc.imageUrl!)
                                      : null,
                                  child: doc.imageUrl == null || doc.imageUrl!.isEmpty
                                      ? const Icon(Icons.medical_services_outlined)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        doc.specialty,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
class _FindDoctorsModule extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final String specialtyFilter;
  final bool onlyAvailable;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSpecialtyChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  final void Function(DoctorEntity doctor) onBookDoctor;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onViewDoctor;

  const _FindDoctorsModule({
    required this.searchController,
    required this.query,
    required this.specialtyFilter,
    required this.onlyAvailable,
    required this.onQueryChanged,
    required this.onSpecialtyChanged,
    required this.onAvailabilityChanged,
    required this.onBookDoctor,
    required this.onViewDoctor,
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
                'Find doctors',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Search by specialty and availability.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SpecialtyFilter(
                      selected: specialtyFilter,
                      onChanged: onSpecialtyChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Switch(
                        value: onlyAvailable,
                        onChanged: onAvailabilityChanged,
                      ),
                      const Text('Available now'),
                    ],
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
                  .collection('doctors')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load doctors'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No doctors available'));
                }

                return FutureBuilder<Map<String, bool>>(
                  future: _prefetchAvailabilityStatus(docs),
                  builder: (context, availabilitySnap) {
                    final availability = availabilitySnap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final filtered = docs.where((doc) {
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? '';
                      final specialty = (data['specialty'] as String?) ?? '';
                      if (specialtyFilter != 'All' && specialty != specialtyFilter) return false;
                      if (onlyAvailable && availability[doc.id] != true) return false;
                      if (normalized.isEmpty) return true;
                      return name.toLowerCase().contains(normalized) ||
                          specialty.toLowerCase().contains(normalized);
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
                        final specialty = (data['specialty'] as String?) ?? 'Specialist';
                        final imageUrl = data['profileImageUrl'] as String?;
                        final available = availability[doc.id] == true;

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null || imageUrl.isEmpty
                                        ? const Icon(Icons.medical_services_outlined)
                                        : null,
                                  ),
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
                                        Text(
                                          specialty,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusPill(label: available ? 'Available' : 'No slots', active: available),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => onViewDoctor(doc),
                                    icon: const Icon(Icons.info_outline),
                                    label: const Text('View profile'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => onBookDoctor(
                                      DoctorEntity(id: doc.id, name: name, specialty: specialty),
                                    ),
                                    icon: const Icon(Icons.calendar_month_outlined),
                                    label: const Text('Book now'),
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

  Future<Map<String, bool>> _prefetchAvailabilityStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final result = <String, bool>{};
    final db = FirebaseFirestore.instance;
    final now = Timestamp.fromDate(DateTime.now());
    for (final doc in docs) {
      final slots = await db
          .collection('availability')
          .doc(doc.id)
          .collection('slots')
          .where('isBooked', isEqualTo: false)
          .where('startTime', isGreaterThan: now)
          .limit(1)
          .get();
      result[doc.id] = slots.docs.isNotEmpty;
    }
    return result;
  }
}

class _SpecialtyFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SpecialtyFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('doctors').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final specialties = <String>{'All'};
        for (final doc in docs) {
          final data = doc.data();
          final spec = (data['specialty'] as String?) ?? '';
          if (spec.isNotEmpty) specialties.add(spec);
        }

        return DropdownButtonFormField<String>(
          value: specialties.contains(selected) ? selected : 'All',
          decoration: const InputDecoration(labelText: 'Specialty'),
          items: specialties
              .map((spec) => DropdownMenuItem(
                    value: spec,
                    child: Text(spec),
                  ))
              .toList(),
          onChanged: (value) => onChanged(value ?? 'All'),
        );
      },
    );
  }
}
class _PatientAppointmentsModule extends StatelessWidget {
  final String userId;
  final TextEditingController searchController;
  final String query;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;
  final Future<void> Function(String appointmentId) onCancel;
  final bool Function(DateTime dateTime, String status) canCancel;

  const _PatientAppointmentsModule({
    required this.userId,
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.fetchDoctorNames,
    required this.onCancel,
    required this.canCancel,
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
                'My appointments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Track and manage your bookings.',
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
                        hintText: 'Search by doctor',
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
                  .where('userId', isEqualTo: userId)
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
                  return const Center(child: Text('No appointments yet'));
                }

                final list = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  if (statusFilter != 'all' && statusFilter != status) continue;
                  final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                  list.add(_AppointmentView(
                    id: doc.id,
                    doctorId: (data['doctorId'] as String?) ?? '',
                    dateTime: dt,
                    status: status,
                  ));
                }

                list.sort((a, b) => a.dateTime.compareTo(b.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchDoctorNames(list.map((e) => e.doctorId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    final normalized = query.trim().toLowerCase();
                    final visible = list.where((appt) {
                      if (normalized.isEmpty) return true;
                      final dname = (names[appt.doctorId] ?? appt.doctorId).toLowerCase();
                      return dname.contains(normalized);
                    }).toList();

                    if (visible.isEmpty) {
                      return const Center(child: Text('No matching appointments'));
                    }

                    return ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = visible[index];
                        final dname = names[appt.doctorId] ?? appt.doctorId;
                        final allowCancel = canCancel(appt.dateTime, appt.status);

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dname,
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
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: allowCancel ? () => onCancel(appt.id) : null,
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Cancel'),
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
}

class _MedicalHistoryModule extends StatelessWidget {
  final String userId;
  final Future<Map<String, String>> Function(Set<String> ids) fetchDoctorNames;

  const _MedicalHistoryModule({
    required this.userId,
    required this.fetchDoctorNames,
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
                'Medical history',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed appointments and shared notes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load medical history'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No completed appointments yet'));
                }

                final completed = <_AppointmentView>[];
                for (final doc in docs) {
                  final data = doc.data();
                  final status = (data['status'] as String?) ?? 'pending';
                  if (status != 'completed') continue;
                  final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
                  completed.add(_AppointmentView(
                    id: doc.id,
                    doctorId: (data['doctorId'] as String?) ?? '',
                    dateTime: dt,
                    status: status,
                    notes: data['notes'] as String?,
                  ));
                }

                if (completed.isEmpty) {
                  return const Center(child: Text('No completed appointments yet'));
                }

                completed.sort((a, b) => b.dateTime.compareTo(a.dateTime));

                return FutureBuilder<Map<String, String>>(
                  future: fetchDoctorNames(completed.map((e) => e.doctorId).toSet()),
                  builder: (context, nameSnap) {
                    final names = nameSnap.data ?? {};
                    return ListView.separated(
                      itemCount: completed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final appt = completed[index];
                        final dname = names[appt.doctorId] ?? appt.doctorId;
                        final notes = appt.notes?.trim() ?? '';

                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dname,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusPill(label: 'completed', active: true),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_formatDateTime(appt.dateTime)),
                              const SizedBox(height: 8),
                              Text(
                                notes.isEmpty ? 'Notes: No notes shared yet.' : 'Notes: $notes',
                                style: Theme.of(context).textTheme.bodySmall,
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

class _ProfileSettingsModule extends StatelessWidget {
  final String userId;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController dobController;
  final TextEditingController photoController;
  final bool profileLoaded;
  final void Function(Map<String, dynamic>? data) onLoadProfile;
  final ValueChanged<bool> setProfileLoaded;
  final VoidCallback onSaveProfile;

  const _ProfileSettingsModule({
    required this.userId,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.dobController,
    required this.photoController,
    required this.profileLoaded,
    required this.onLoadProfile,
    required this.setProfileLoaded,
    required this.onSaveProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
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
                      'Keep your contact details up to date.',
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
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone number'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dobController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(labelText: 'Date of birth (YYYY-MM-DD)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: photoController,
                      decoration: const InputDecoration(labelText: 'Profile photo URL'),
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
