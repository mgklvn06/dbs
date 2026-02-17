// ignore_for_file: deprecated_member_use, unused_element_parameter, use_build_context_synchronously, invalid_use_of_protected_member

part of 'patient_dashboard_page.dart';

extension _PatientDashboardPageStateNavigationExt
    on _PatientDashboardPageState {
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
                  Navigator.pushReplacementNamed(context, Routes.landing);
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
                child: Icon(
                  Icons.favorite_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Console',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
          preferredDoctorIds: _preferredDoctorIds,
          onQueryChanged: (value) => setState(() => _doctorQuery = value),
          onSpecialtyChanged: (value) =>
              setState(() => _specialtyFilter = value),
          onAvailabilityChanged: (value) =>
              setState(() => _onlyAvailable = value),
          onTogglePreferredDoctor: (doctorId, preferred) =>
              _togglePreferredDoctor(
                context,
                userId: userId,
                doctorId: doctorId,
                preferred: preferred,
              ),
          onBookDoctor: (doctor) => _handleBookDoctor(context, doctor),
          onViewDoctor: (doc) => _showDoctorDetails(context, doc),
        );
      case 2:
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('system')
              .snapshots(),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data?.data() ?? <String, dynamic>{};
            final booking = _readMap(settings['booking']);
            final cancellationDeadlineHours = _readInt(
              booking['cancellationDeadlineHours'],
              6,
            );
            return _PatientAppointmentsModule(
              userId: userId,
              searchController: _appointmentSearchController,
              query: _appointmentQuery,
              statusFilter: _appointmentStatus,
              onQueryChanged: (value) =>
                  setState(() => _appointmentQuery = value),
              onStatusChanged: (value) =>
                  setState(() => _appointmentStatus = value),
              fetchDoctorNames: _prefetchDoctorNames,
              onCancel: (id) => _cancelAppointment(
                context,
                id,
                cancellationDeadlineHours: cancellationDeadlineHours,
              ),
              canCancel: (dateTime, status) => _canCancelAppointment(
                dateTime,
                status,
                cancellationDeadlineHours,
              ),
            );
          },
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
          preferredSpecialtyController: _preferredSpecialtyController,
          maxDistanceController: _maxDistanceController,
          preferredDurationController: _preferredDurationController,
          sharePhoneWithDoctors: _sharePhoneWithDoctors,
          shareProfileImageWithDoctors: _shareProfileImageWithDoctors,
          profileVisibility: _profileVisibility,
          reminderLeadTime: _reminderLeadTime,
          notifyBookingConfirmations: _notifyBookingConfirmations,
          notifyBookingReminders: _notifyBookingReminders,
          notifyCancellationAlerts: _notifyCancellationAlerts,
          notifySystemAnnouncements: _notifySystemAnnouncements,
          preferredDoctorsCount: _preferredDoctorIds.length,
          hasGoogleLinked: _hasProviderLinked('google.com'),
          hasPasswordLinked: _hasProviderLinked('password'),
          profileLoaded: _profileLoaded,
          onLoadProfile: _loadProfileFields,
          setProfileLoaded: (value) => _profileLoaded = value,
          onSharePhoneChanged: (value) =>
              setState(() => _sharePhoneWithDoctors = value),
          onShareProfileImageChanged: (value) =>
              setState(() => _shareProfileImageWithDoctors = value),
          onProfileVisibilityChanged: (value) =>
              setState(() => _profileVisibility = value),
          onReminderLeadTimeChanged: (value) =>
              setState(() => _reminderLeadTime = value),
          onNotifyBookingConfirmationsChanged: (value) =>
              setState(() => _notifyBookingConfirmations = value),
          onNotifyBookingRemindersChanged: (value) =>
              setState(() => _notifyBookingReminders = value),
          onNotifyCancellationAlertsChanged: (value) =>
              setState(() => _notifyCancellationAlerts = value),
          onNotifySystemAnnouncementsChanged: (value) =>
              setState(() => _notifySystemAnnouncements = value),
          onSaveProfile: () => _saveProfile(context, userId),
          onUploadPhoto: () => _uploadProfilePhoto(context, userId),
          onChangePassword: () => _promptChangePassword(context),
          onDeleteAccount: () => _promptDeleteAccount(context),
          onLogout: () => _logoutFromSettings(context),
          accountActionRunning: _isAccountActionRunning,
          isUploadingPhoto: _isUploadingPhoto,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
