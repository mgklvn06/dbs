// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, invalid_use_of_protected_member

part of 'doctor_profile_page.dart';

extension _DoctorProfilePageStateNavigationExt on _DoctorProfilePageState {
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

  Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
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
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    return fallback;
  }

  String _normalizeConsultationType(dynamic raw) {
    final value = '$raw'.trim().toLowerCase();
    if (value == 'online' || value == 'physical' || value == 'both') {
      return value;
    }
    return 'both';
  }

  bool _hasProviderLinked(String providerId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (provider) => provider.providerId == providerId,
    );
  }

  Future<_DoctorBookingActionPolicy> _loadDoctorBookingActionPolicy() async {
    final settingsSnap = await FirebaseFirestore.instance
        .collection('settings')
        .doc('system')
        .get();
    final settings = settingsSnap.data() ?? <String, dynamic>{};
    final booking = _readMap(settings['booking']);
    final doctorBookingEnabled = _readBool(
      booking['doctorBookingEnabled'],
      true,
    );
    return _DoctorBookingActionPolicy(
      doctorBookingEnabled: doctorBookingEnabled,
    );
  }

  Widget _buildPage(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
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
                                  label: 'Appointments',
                                  icon: Icons.event_note_outlined,
                                  onTap: () => _selectModule(1),
                                ),
                                const SizedBox(width: 10),
                                _QuickActionChip(
                                  label: 'Availability',
                                  icon: Icons.schedule_outlined,
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
                child: Icon(
                  Icons.medical_services,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor Console',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('system')
              .snapshots(),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data?.data() ?? <String, dynamic>{};
            final booking = _readMap(settings['booking']);
            final doctorBookingEnabled = _readBool(
              booking['doctorBookingEnabled'],
              true,
            );
            return _DoctorAppointmentsModule(
              doctorId: doctorId,
              searchController: _appointmentSearchController,
              query: _appointmentQuery,
              statusFilter: _statusFilter,
              doctorBookingEnabled: doctorBookingEnabled,
              onQueryChanged: (value) =>
                  setState(() => _appointmentQuery = value),
              onStatusChanged: (value) => setState(() => _statusFilter = value),
              fetchNames: _prefetchUserNames,
              onUpdateStatus: (id, status) =>
                  _updateAppointmentStatus(context, id, status),
              onAddNotes: (id, current) =>
                  _promptAppointmentNotes(context, id, current),
            );
          },
        );
      case 2:
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
      case 3:
        return _DoctorPatientsModule(
          doctorId: doctorId,
          searchController: _patientSearchController,
          query: _patientQuery,
          onQueryChanged: (value) => setState(() => _patientQuery = value),
          fetchUserDetails: _prefetchUserDetails,
          onViewHistory: (id, name) =>
              _showUserAppointmentHistory(context, doctorId, id, name),
        );
      case 4:
        return _DoctorProfileSettingsModule(
          doctorId: doctorId,
          nameController: _profileNameController,
          specialtyController: _profileSpecialtyController,
          bioController: _profileBioController,
          experienceController: _profileExperienceController,
          feeController: _profileFeeController,
          licenseController: _profileLicenseController,
          imageController: _profileImageController,
          contactEmailController: _profileContactEmailController,
          contactPhoneController: _profileContactPhoneController,
          consultationType: _consultationType,
          profileVisible: _profileVisible,
          acceptingBookings: _acceptingBookings,
          dailyBookingCapController: _dailyBookingCapController,
          autoConfirmBookings: _autoConfirmBookings,
          allowRescheduling: _allowRescheduling,
          cancellationWindowController: _cancellationWindowController,
          newBookingAlerts: _newBookingAlerts,
          cancellationAlerts: _cancellationAlerts,
          dailySummaryEmail: _dailySummaryEmail,
          reminderAlerts: _reminderAlerts,
          onConsultationTypeChanged: (value) =>
              setState(() => _consultationType = value),
          onProfileVisibleChanged: (value) =>
              setState(() => _profileVisible = value),
          onAcceptingBookingsChanged: (value) =>
              setState(() => _acceptingBookings = value),
          onAutoConfirmBookingsChanged: (value) =>
              setState(() => _autoConfirmBookings = value),
          onAllowReschedulingChanged: (value) =>
              setState(() => _allowRescheduling = value),
          onNewBookingAlertsChanged: (value) =>
              setState(() => _newBookingAlerts = value),
          onCancellationAlertsChanged: (value) =>
              setState(() => _cancellationAlerts = value),
          onDailySummaryEmailChanged: (value) =>
              setState(() => _dailySummaryEmail = value),
          onReminderAlertsChanged: (value) =>
              setState(() => _reminderAlerts = value),
          onSaveProfile: () => _saveProfile(context, doctorId),
          onUploadImage: () => _uploadDoctorProfileImage(context, doctorId),
          hasGoogleLinked: _hasProviderLinked('google.com'),
          hasPasswordLinked: _hasProviderLinked('password'),
          onChangePassword: () => _promptDoctorChangePassword(context),
          onRequestDeletion: () => _requestDoctorDeletion(context, doctorId),
          accountActionRunning: _isDoctorAccountActionRunning,
          isUploadingImage: _isUploadingProfileImage,
          onLoadProfile: _loadProfileFields,
          profileLoaded: _profileLoaded,
          setProfileLoaded: (value) => _profileLoaded = value,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
