// ignore_for_file: deprecated_member_use

part of 'patient_dashboard_page.dart';

class _ProfileSettingsModule extends StatelessWidget {
  final String userId;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController dobController;
  final TextEditingController photoController;
  final TextEditingController preferredSpecialtyController;
  final TextEditingController maxDistanceController;
  final TextEditingController preferredDurationController;
  final bool sharePhoneWithDoctors;
  final bool shareProfileImageWithDoctors;
  final String profileVisibility;
  final String reminderLeadTime;
  final bool notifyBookingConfirmations;
  final bool notifyBookingReminders;
  final bool notifyCancellationAlerts;
  final bool notifySystemAnnouncements;
  final int preferredDoctorsCount;
  final bool hasGoogleLinked;
  final bool hasPasswordLinked;
  final bool profileLoaded;
  final void Function(Map<String, dynamic>? data) onLoadProfile;
  final ValueChanged<bool> setProfileLoaded;
  final ValueChanged<bool> onSharePhoneChanged;
  final ValueChanged<bool> onShareProfileImageChanged;
  final ValueChanged<String> onProfileVisibilityChanged;
  final ValueChanged<String> onReminderLeadTimeChanged;
  final ValueChanged<bool> onNotifyBookingConfirmationsChanged;
  final ValueChanged<bool> onNotifyBookingRemindersChanged;
  final ValueChanged<bool> onNotifyCancellationAlertsChanged;
  final ValueChanged<bool> onNotifySystemAnnouncementsChanged;
  final VoidCallback onSaveProfile;
  final VoidCallback onUploadPhoto;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;
  final bool accountActionRunning;
  final bool isUploadingPhoto;

  const _ProfileSettingsModule({
    required this.userId,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.dobController,
    required this.photoController,
    required this.preferredSpecialtyController,
    required this.maxDistanceController,
    required this.preferredDurationController,
    required this.sharePhoneWithDoctors,
    required this.shareProfileImageWithDoctors,
    required this.profileVisibility,
    required this.reminderLeadTime,
    required this.notifyBookingConfirmations,
    required this.notifyBookingReminders,
    required this.notifyCancellationAlerts,
    required this.notifySystemAnnouncements,
    required this.preferredDoctorsCount,
    required this.hasGoogleLinked,
    required this.hasPasswordLinked,
    required this.profileLoaded,
    required this.onLoadProfile,
    required this.setProfileLoaded,
    required this.onSharePhoneChanged,
    required this.onShareProfileImageChanged,
    required this.onProfileVisibilityChanged,
    required this.onReminderLeadTimeChanged,
    required this.onNotifyBookingConfirmationsChanged,
    required this.onNotifyBookingRemindersChanged,
    required this.onNotifyCancellationAlertsChanged,
    required this.onNotifySystemAnnouncementsChanged,
    required this.onSaveProfile,
    required this.onUploadPhoto,
    required this.onChangePassword,
    required this.onDeleteAccount,
    required this.onLogout,
    required this.accountActionRunning,
    required this.isUploadingPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load profile: ${snapshot.error}'),
          );
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
                      'Account settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your identity, privacy, booking preferences, and notifications.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
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
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Date of birth (YYYY-MM-DD)',
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
                      'Privacy settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: sharePhoneWithDoctors,
                      onChanged: onSharePhoneChanged,
                      title: const Text('Allow doctors to view phone number'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: shareProfileImageWithDoctors,
                      onChanged: onShareProfileImageChanged,
                      title: const Text('Allow doctors to view profile image'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: profileVisibility,
                      decoration: const InputDecoration(
                        labelText: 'Profile visibility',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'appointment_only',
                          child: Text('Appointment-only'),
                        ),
                      ],
                      onChanged: (value) => onProfileVisibilityChanged(
                        value ?? 'appointment_only',
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
                      'Booking preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: preferredSpecialtyController,
                      decoration: const InputDecoration(
                        labelText: 'Default preferred specialty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxDistanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max distance preference (km)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: reminderLeadTime,
                      decoration: const InputDecoration(
                        labelText: 'Reminder lead time',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '1h',
                          child: Text('1 hour before'),
                        ),
                        DropdownMenuItem(
                          value: '24h',
                          child: Text('24 hours before'),
                        ),
                      ],
                      onChanged: (value) =>
                          onReminderLeadTimeChanged(value ?? '24h'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: preferredDurationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preferred appointment duration (minutes)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Preferred doctors saved: $preferredDoctorsCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: notifyBookingConfirmations,
                      onChanged: onNotifyBookingConfirmationsChanged,
                      title: const Text('Booking confirmations'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: notifyBookingReminders,
                      onChanged: onNotifyBookingRemindersChanged,
                      title: const Text('Booking reminders'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: notifyCancellationAlerts,
                      onChanged: onNotifyCancellationAlertsChanged,
                      title: const Text('Cancellation alerts'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: notifySystemAnnouncements,
                      onChanged: onNotifySystemAnnouncementsChanged,
                      title: const Text('System announcements'),
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
                      'Profile photo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: photoController,
                      builder: (context, value, _) {
                        final imageUrl = value.text.trim();
                        final hasImage = imageUrl.isNotEmpty;
                        final theme = Theme.of(context);
                        final placeholder = Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.primary,
                          ),
                        );

                        return Row(
                          children: [
                            if (hasImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      placeholder,
                                ),
                              )
                            else
                              placeholder,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasImage
                                    ? 'Your uploaded profile photo is shown here.'
                                    : 'No profile photo uploaded yet.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.65),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: isUploadingPhoto ? null : onUploadPhoto,
                        icon: isUploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          isUploadingPhoto ? 'Uploading...' : 'Upload photo',
                        ),
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
                      'Security and access',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: hasGoogleLinked
                              ? 'Google linked'
                              : 'Google not linked',
                          active: hasGoogleLinked,
                        ),
                        _StatusPill(
                          label: hasPasswordLinked
                              ? 'Password login enabled'
                              : 'Password login disabled',
                          active: hasPasswordLinked,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: accountActionRunning
                              ? null
                              : onSaveProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save settings'),
                        ),
                        OutlinedButton.icon(
                          onPressed: accountActionRunning
                              ? null
                              : onChangePassword,
                          icon: const Icon(Icons.lock_reset_outlined),
                          label: const Text('Change password'),
                        ),
                        OutlinedButton.icon(
                          onPressed: accountActionRunning ? null : onLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                        OutlinedButton.icon(
                          onPressed: accountActionRunning
                              ? null
                              : onDeleteAccount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete account'),
                        ),
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
