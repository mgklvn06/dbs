// ignore_for_file: deprecated_member_use, unused_element_parameter, use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/core/widgets/user_theme_toggle_button.dart';
import 'package:dbs/core/services/appointment_policy_service.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:dbs/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

part 'patient_dashboard_shared.dart';
part 'patient_dashboard_overview_module.dart';
part 'patient_dashboard_find_doctors_module.dart';
part 'patient_dashboard_appointments_module.dart';
part 'patient_dashboard_medical_history_module.dart';
part 'patient_dashboard_profile_settings_module.dart';
part 'patient_dashboard_models.dart';
part 'patient_dashboard_state_navigation.dart';
part 'patient_dashboard_state_appointments.dart';
part 'patient_dashboard_state_profile.dart';
part 'patient_dashboard_state_account.dart';

class PatientDashboardPage extends StatefulWidget {
  final int initialIndex;

  const PatientDashboardPage({super.key, this.initialIndex = 0});

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

  late int _selectedIndex;

  final TextEditingController _doctorSearchController = TextEditingController();
  final TextEditingController _appointmentSearchController =
      TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  final TextEditingController _profileAddressController =
      TextEditingController();
  final TextEditingController _profileDobController = TextEditingController();
  final TextEditingController _profilePhotoController = TextEditingController();
  final TextEditingController _preferredSpecialtyController =
      TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController(
    text: '20',
  );
  final TextEditingController _preferredDurationController =
      TextEditingController(text: '30');
  final _imagePicker = ImagePicker();

  String _doctorQuery = '';
  bool _onlyAvailable = false;
  String _specialtyFilter = 'All';

  String _appointmentQuery = '';
  String _appointmentStatus = 'all';

  bool _profileLoaded = false;
  bool _isUploadingPhoto = false;
  bool _sharePhoneWithDoctors = true;
  bool _shareProfileImageWithDoctors = true;
  String _profileVisibility = 'appointment_only';
  String _reminderLeadTime = '24h';
  bool _notifyBookingConfirmations = true;
  bool _notifyBookingReminders = true;
  bool _notifyCancellationAlerts = true;
  bool _notifySystemAnnouncements = true;
  Set<String> _preferredDoctorIds = <String>{};
  bool _isAccountActionRunning = false;
  late Future<_PatientDashboardMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIndex;
    _selectedIndex = (initial >= 0 && initial < _navItems.length) ? initial : 0;
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
    _preferredSpecialtyController.dispose();
    _maxDistanceController.dispose();
    _preferredDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
