// ignore_for_file: deprecated_member_use

part of 'doctor_profile_page.dart';

class _DoctorProfileSettingsModule extends StatelessWidget {
  final String doctorId;
  final TextEditingController nameController;
  final TextEditingController specialtyController;
  final TextEditingController bioController;
  final TextEditingController experienceController;
  final TextEditingController feeController;
  final TextEditingController licenseController;
  final TextEditingController imageController;
  final TextEditingController contactEmailController;
  final TextEditingController contactPhoneController;
  final String consultationType;
  final bool profileVisible;
  final bool acceptingBookings;
  final TextEditingController dailyBookingCapController;
  final bool autoConfirmBookings;
  final bool allowRescheduling;
  final TextEditingController cancellationWindowController;
  final bool newBookingAlerts;
  final bool cancellationAlerts;
  final bool dailySummaryEmail;
  final bool reminderAlerts;
  final ValueChanged<String> onConsultationTypeChanged;
  final ValueChanged<bool> onProfileVisibleChanged;
  final ValueChanged<bool> onAcceptingBookingsChanged;
  final ValueChanged<bool> onAutoConfirmBookingsChanged;
  final ValueChanged<bool> onAllowReschedulingChanged;
  final ValueChanged<bool> onNewBookingAlertsChanged;
  final ValueChanged<bool> onCancellationAlertsChanged;
  final ValueChanged<bool> onDailySummaryEmailChanged;
  final ValueChanged<bool> onReminderAlertsChanged;
  final VoidCallback onSaveProfile;
  final VoidCallback onUploadImage;
  final bool hasGoogleLinked;
  final bool hasPasswordLinked;
  final VoidCallback onChangePassword;
  final VoidCallback onRequestDeletion;
  final bool accountActionRunning;
  final bool isUploadingImage;
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
    required this.licenseController,
    required this.imageController,
    required this.contactEmailController,
    required this.contactPhoneController,
    required this.consultationType,
    required this.profileVisible,
    required this.acceptingBookings,
    required this.dailyBookingCapController,
    required this.autoConfirmBookings,
    required this.allowRescheduling,
    required this.cancellationWindowController,
    required this.newBookingAlerts,
    required this.cancellationAlerts,
    required this.dailySummaryEmail,
    required this.reminderAlerts,
    required this.onConsultationTypeChanged,
    required this.onProfileVisibleChanged,
    required this.onAcceptingBookingsChanged,
    required this.onAutoConfirmBookingsChanged,
    required this.onAllowReschedulingChanged,
    required this.onNewBookingAlertsChanged,
    required this.onCancellationAlertsChanged,
    required this.onDailySummaryEmailChanged,
    required this.onReminderAlertsChanged,
    required this.onSaveProfile,
    required this.onUploadImage,
    required this.hasGoogleLinked,
    required this.hasPasswordLinked,
    required this.onChangePassword,
    required this.onRequestDeletion,
    required this.accountActionRunning,
    required this.isUploadingImage,
    required this.onLoadProfile,
    required this.profileLoaded,
    required this.setProfileLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
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
                      'Profile settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep your professional data accurate.',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      controller: licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience (years)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Consultation fee',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: consultationType,
                      decoration: const InputDecoration(
                        labelText: 'Consultation type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'physical',
                          child: Text('Physical'),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Online and physical'),
                        ),
                      ],
                      onChanged: (value) =>
                          onConsultationTypeChanged(value ?? 'both'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: profileVisible,
                      onChanged: onProfileVisibleChanged,
                      title: const Text('Profile visible to patients'),
                      subtitle: const Text(
                        'Hide your profile without admin action',
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
                      'Availability controls',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: acceptingBookings,
                      onChanged: onAcceptingBookingsChanged,
                      title: const Text('Accept new bookings'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dailyBookingCapController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily booking cap (0 = unlimited)',
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
                      'Booking behavior',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: autoConfirmBookings,
                      onChanged: onAutoConfirmBookingsChanged,
                      title: const Text('Auto-confirm bookings'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: allowRescheduling,
                      onChanged: onAllowReschedulingChanged,
                      title: const Text('Allow patient rescheduling'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cancellationWindowController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cancellation window (hours)',
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
                      'Notification preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: newBookingAlerts,
                      onChanged: onNewBookingAlertsChanged,
                      title: const Text('New booking alerts'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: cancellationAlerts,
                      onChanged: onCancellationAlertsChanged,
                      title: const Text('Cancellation alerts'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: dailySummaryEmail,
                      onChanged: onDailySummaryEmailChanged,
                      title: const Text('Daily summary email'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: reminderAlerts,
                      onChanged: onReminderAlertsChanged,
                      title: const Text('Reminder alerts'),
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
                      'Profile image',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: imageController,
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
                                    ? 'Your uploaded profile image is displayed here.'
                                    : 'No profile image uploaded yet.',
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
                        onPressed: isUploadingImage ? null : onUploadImage,
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          isUploadingImage ? 'Uploading...' : 'Upload image',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone',
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
                      'Security and account actions',
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
                          label: const Text('Save profile'),
                        ),
                        OutlinedButton.icon(
                          onPressed: accountActionRunning
                              ? null
                              : onChangePassword,
                          icon: const Icon(Icons.lock_reset_outlined),
                          label: const Text('Change password'),
                        ),
                        OutlinedButton.icon(
                          onPressed: accountActionRunning
                              ? null
                              : onRequestDeletion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Request account deletion'),
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
