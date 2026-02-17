// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, invalid_use_of_protected_member

part of 'doctor_profile_page.dart';

extension _DoctorProfilePageStateProfileExt on _DoctorProfilePageState {
  Future<void> _saveProfile(BuildContext context, String doctorId) async {
    final name = _profileNameController.text.trim();
    final specialty = _profileSpecialtyController.text.trim();
    final bio = _profileBioController.text.trim();
    final exp = int.tryParse(_profileExperienceController.text.trim());
    final fee = double.tryParse(_profileFeeController.text.trim());
    final licenseNumber = _profileLicenseController.text.trim();
    final image = _profileImageController.text.trim();
    final contactEmail = _profileContactEmailController.text.trim();
    final contactPhone = _profileContactPhoneController.text.trim();
    final dailyBookingCap = max(
      0,
      _readInt(_dailyBookingCapController.text.trim(), 0),
    );
    final cancellationWindowHours = max(
      0,
      _readInt(_cancellationWindowController.text.trim(), 3),
    );

    final payload = <String, dynamic>{
      'name': name,
      'specialty': specialty,
      'bio': bio,
      if (exp != null) 'experienceYears': exp,
      if (fee != null) 'consultationFee': fee,
      if (licenseNumber.isNotEmpty) 'licenseNumber': licenseNumber,
      'consultationType': _consultationType,
      'profileVisible': _profileVisible,
      'acceptingBookings': _acceptingBookings,
      'bookingPreferences': {
        'autoConfirmBookings': _autoConfirmBookings,
        'allowRescheduling': _allowRescheduling,
        'cancellationWindowHours': cancellationWindowHours,
        'dailyBookingCap': dailyBookingCap,
      },
      'notificationPreferences': {
        'newBookingAlerts': _newBookingAlerts,
        'cancellationAlerts': _cancellationAlerts,
        'dailySummaryEmail': _dailySummaryEmail,
        'reminderAlerts': _reminderAlerts,
      },
      if (image.isNotEmpty) 'profileImageUrl': image,
      if (contactEmail.isNotEmpty) 'contactEmail': contactEmail,
      if (contactPhone.isNotEmpty) 'contactPhone': contactPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final db = FirebaseFirestore.instance;
      await db
          .collection('doctors')
          .doc(doctorId)
          .set(payload, SetOptions(merge: true));
      if (name.isNotEmpty) {
        await db.collection('users').doc(doctorId).set({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  Future<void> _promptDoctorChangePassword(BuildContext rootContext) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_hasProviderLinked('password')) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Password change is only available for email/password accounts.',
          ),
        ),
      );
      return;
    }

    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    final newPassword = await showDialog<String>(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final password = passwordController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (password.length < 6) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 6 characters.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (password != confirm) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, password);
                  },
                  child: const Text('Update password'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
    if (newPassword == null || newPassword.isEmpty) return;

    setState(() => _isDoctorAccountActionRunning = true);
    try {
      await user.updatePassword(newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'requires-recent-login'
          ? 'Please sign out and sign in again before changing your password.'
          : e.message ?? 'Failed to update password.';
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text('Failed to update password: $e')));
    } finally {
      if (mounted) setState(() => _isDoctorAccountActionRunning = false);
    }
  }

  Future<void> _requestDoctorDeletion(
    BuildContext rootContext,
    String doctorId,
  ) async {
    if (_isDoctorAccountActionRunning) return;

    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Request account deletion'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This sends your account to admin review. Type DELETE to confirm.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(labelText: 'Type DELETE'),
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
              onPressed: () => Navigator.pop(
                dialogContext,
                confirmController.text.trim().toUpperCase() == 'DELETE',
              ),
              child: const Text('Send request'),
            ),
          ],
        );
      },
    );
    confirmController.dispose();
    if (confirmed != true) return;

    setState(() => _isDoctorAccountActionRunning = true);
    try {
      final now = DateTime.now();
      final appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      final hasUpcomingActive = appointments.docs.any((doc) {
        final data = doc.data();
        final status = (data['status'] as String?) ?? 'pending';
        final active =
            status == 'pending' ||
            status == 'confirmed' ||
            status == 'accepted';
        if (!active) return false;
        final appointmentDate = _parseDate(
          data['appointmentTime'] ?? data['dateTime'],
        );
        return appointmentDate.isAfter(now);
      });

      if (hasUpcomingActive) {
        if (!mounted) return;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(
            content: Text(
              'You still have upcoming active appointments. Resolve them first.',
            ),
          ),
        );
        return;
      }

      final db = FirebaseFirestore.instance;
      await db.collection('users').doc(doctorId).set({
        'accountStatus': 'deletion_requested',
        'deletionRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await db.collection('doctors').doc(doctorId).set({
        'accountStatus': 'deletion_requested',
        'deletionRequestedAt': FieldValue.serverTimestamp(),
        'acceptingBookings': false,
        'profileVisible': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await db.collection('moderation_events').add({
          'kind': 'doctor_account_deletion_request',
          'targetId': doctorId,
          'doctorId': doctorId,
          'status': 'pending_review',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Keep request successful even when moderation queue write is blocked.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text('Deletion request sent. Admin review is required.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text('Failed to request deletion: $e')));
    } finally {
      if (mounted) setState(() => _isDoctorAccountActionRunning = false);
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
    _profileLicenseController.text = (data['licenseNumber'] as String?) ?? '';
    _profileImageController.text = (data['profileImageUrl'] as String?) ?? '';
    _profileContactEmailController.text =
        (data['contactEmail'] as String?) ?? '';
    _profileContactPhoneController.text =
        (data['contactPhone'] as String?) ?? '';
    _consultationType = _normalizeConsultationType(data['consultationType']);
    _profileVisible = _readBool(data['profileVisible'], true);
    _acceptingBookings = _readBool(data['acceptingBookings'], true);

    final bookingPreferences = _readMap(data['bookingPreferences']);
    final notificationPreferences = _readMap(data['notificationPreferences']);

    _autoConfirmBookings = _readBool(
      bookingPreferences['autoConfirmBookings'],
      false,
    );
    _allowRescheduling = _readBool(
      bookingPreferences['allowRescheduling'],
      true,
    );
    _dailyBookingCapController.text =
        '${max(0, _readInt(bookingPreferences['dailyBookingCap'], 0))}';
    _cancellationWindowController.text =
        '${max(0, _readInt(bookingPreferences['cancellationWindowHours'], 3))}';

    _newBookingAlerts = _readBool(
      notificationPreferences['newBookingAlerts'],
      true,
    );
    _cancellationAlerts = _readBool(
      notificationPreferences['cancellationAlerts'],
      true,
    );
    _dailySummaryEmail = _readBool(
      notificationPreferences['dailySummaryEmail'],
      true,
    );
    _reminderAlerts = _readBool(
      notificationPreferences['reminderAlerts'],
      true,
    );
    _profileLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _uploadDoctorProfileImage(
    BuildContext context,
    String doctorId,
  ) async {
    if (_isUploadingProfileImage) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _isUploadingProfileImage = true);
    try {
      final uploader = GetIt.instance<UploadAvatarUseCase>();
      final bytes = await picked.readAsBytes();
      final fallbackName = picked.name.trim().isEmpty
          ? 'avatar.jpg'
          : picked.name.trim();
      final url = await uploader(bytes: bytes, fileName: fallbackName);
      _profileImageController.text = url;

      final db = FirebaseFirestore.instance;
      await db.collection('doctors').doc(doctorId).set({
        'profileImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await db.collection('users').doc(doctorId).set({
        'photoUrl': url,
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingProfileImage = false);
    }
  }
}
