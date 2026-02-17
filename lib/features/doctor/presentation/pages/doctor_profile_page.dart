// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/services/appointment_policy_service.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/core/widgets/user_theme_toggle_button.dart';
import 'package:dbs/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

part 'doctor_profile_shared.dart';
part 'doctor_profile_dashboard_module.dart';
part 'doctor_profile_appointments_module.dart';
part 'doctor_profile_availability_module.dart';
part 'doctor_profile_patients_module.dart';
part 'doctor_profile_settings_module.dart';
part 'doctor_profile_models.dart';
part 'doctor_profile_state_navigation.dart';
part 'doctor_profile_state_appointments.dart';
part 'doctor_profile_state_profile.dart';
part 'doctor_profile_state_availability_dashboard.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _navItems = const [
    _DoctorNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
    _DoctorNavItem(label: 'Appointments', icon: Icons.event_note_outlined),
    _DoctorNavItem(label: 'Availability', icon: Icons.schedule_outlined),
    _DoctorNavItem(label: 'Patients', icon: Icons.people_outline),
    _DoctorNavItem(label: 'Profile Settings', icon: Icons.settings_outlined),
  ];

  int _selectedIndex = 0;

  final TextEditingController _appointmentSearchController =
      TextEditingController();
  final TextEditingController _patientSearchController =
      TextEditingController();

  String _appointmentQuery = '';
  String _patientQuery = '';
  String _statusFilter = 'all';

  late Future<_DoctorDashboardMetrics> _metricsFuture;

  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profileSpecialtyController =
      TextEditingController();
  final TextEditingController _profileBioController = TextEditingController();
  final TextEditingController _profileExperienceController =
      TextEditingController();
  final TextEditingController _profileFeeController = TextEditingController();
  final TextEditingController _profileLicenseController =
      TextEditingController();
  final TextEditingController _profileImageController = TextEditingController();
  final TextEditingController _profileContactEmailController =
      TextEditingController();
  final TextEditingController _profileContactPhoneController =
      TextEditingController();
  final TextEditingController _dailyBookingCapController =
      TextEditingController(text: '0');
  final TextEditingController _cancellationWindowController =
      TextEditingController(text: '3');
  final _imagePicker = ImagePicker();

  final TextEditingController _availStartController = TextEditingController(
    text: '09:00',
  );
  final TextEditingController _availEndController = TextEditingController(
    text: '17:00',
  );
  final TextEditingController _availSlotDurationController =
      TextEditingController(text: '30');
  final TextEditingController _availBreakStartController =
      TextEditingController(text: '12:00');
  final TextEditingController _availBreakEndController = TextEditingController(
    text: '13:00',
  );
  final TextEditingController _availBlockedDatesController =
      TextEditingController();

  final Set<int> _workingDays = {1, 2, 3, 4, 5};

  bool _profileLoaded = false;
  bool _availabilityLoaded = false;
  bool _isGeneratingSlots = false;
  bool _isUploadingProfileImage = false;
  bool _profileVisible = true;
  bool _acceptingBookings = true;
  String _consultationType = 'both';
  bool _autoConfirmBookings = false;
  bool _allowRescheduling = true;
  bool _newBookingAlerts = true;
  bool _cancellationAlerts = true;
  bool _dailySummaryEmail = true;
  bool _reminderAlerts = true;
  bool _isDoctorAccountActionRunning = false;

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
    _profileLicenseController.dispose();
    _profileImageController.dispose();
    _profileContactEmailController.dispose();
    _profileContactPhoneController.dispose();
    _dailyBookingCapController.dispose();
    _cancellationWindowController.dispose();
    _availStartController.dispose();
    _availEndController.dispose();
    _availSlotDurationController.dispose();
    _availBreakStartController.dispose();
    _availBreakEndController.dispose();
    _availBlockedDatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
