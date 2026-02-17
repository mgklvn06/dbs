// ignore_for_file: deprecated_member_use, unused_element_parameter, use_build_context_synchronously, invalid_use_of_protected_member

part of 'patient_dashboard_page.dart';

extension _PatientDashboardPageStateProfileExt on _PatientDashboardPageState {
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
    final userSnap = await db.collection('users').doc(userId).get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final preferredRaw = userData['preferredDoctorIds'];
    final preferredIds = preferredRaw is List
        ? preferredRaw
              .map((e) => '$e')
              .where((e) => e.trim().isNotEmpty)
              .toSet()
        : <String>{};
    final apptsSnap = await db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .get();

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

      final isActive =
          status == 'pending' || status == 'confirmed' || status == 'accepted';
      final isFinal = status == 'completed' || status == 'no_show';
      final isUpcoming = isActive && dt.isAfter(now);
      final isPast = dt.isBefore(now) && (isActive || isFinal);

      if (isUpcoming) {
        upcoming += 1;
        if (next == null || dt.isBefore(next.dateTime)) {
          next = appt;
        }
      } else if (isPast) {
        past += 1;
      }
    }

    final doctorsSnap = await db
        .collection('doctors')
        .where('isActive', isEqualTo: true)
        .limit(12)
        .get();
    final discoverable = doctorsSnap.docs.where((doc) {
      final data = doc.data();
      final visible = _readBool(data['profileVisible'], true);
      final accepting = _readBool(data['acceptingBookings'], true);
      return visible && accepting;
    }).toList();
    discoverable.sort((a, b) {
      final aPreferred = preferredIds.contains(a.id) ? 1 : 0;
      final bPreferred = preferredIds.contains(b.id) ? 1 : 0;
      return bPreferred.compareTo(aPreferred);
    });
    final recommended = discoverable.take(3).map((doc) {
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
      final q = await firestore
          .collection('doctors')
          .where(FieldPath.documentId, whereIn: slice)
          .get();
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
    final photo =
        (data['photoUrl'] as String?) ?? (data['avatarUrl'] as String?) ?? '';
    _profilePhotoController.text = photo;

    final privacy = _readMap(data['privacySettings']);
    final booking = _readMap(data['bookingPreferences']);
    final notifications = _readMap(data['notificationSettings']);

    _sharePhoneWithDoctors = _readBool(privacy['sharePhoneWithDoctors'], true);
    _shareProfileImageWithDoctors = _readBool(
      privacy['shareProfileImageWithDoctors'],
      true,
    );
    _profileVisibility = _normalizeProfileVisibility(
      privacy['profileVisibility'],
    );

    _preferredSpecialtyController.text =
        (booking['defaultPreferredSpecialty'] as String?) ?? '';
    _maxDistanceController.text =
        '${max(0, _readInt(booking['maxDistanceKm'], 20))}';
    _preferredDurationController.text =
        '${max(0, _readInt(booking['preferredAppointmentDurationMinutes'], 30))}';
    _reminderLeadTime = _normalizeReminderLeadTime(booking['reminderLeadTime']);

    _notifyBookingConfirmations = _readBool(
      notifications['bookingConfirmations'],
      true,
    );
    _notifyBookingReminders = _readBool(
      notifications['bookingReminders'],
      true,
    );
    _notifyCancellationAlerts = _readBool(
      notifications['cancellationAlerts'],
      true,
    );
    _notifySystemAnnouncements = _readBool(
      notifications['systemAnnouncements'],
      true,
    );

    final preferredRaw = data['preferredDoctorIds'];
    if (preferredRaw is List) {
      _preferredDoctorIds = preferredRaw
          .map((e) => '$e')
          .where((e) => e.trim().isNotEmpty)
          .toSet();
    }

    final preferredSpecialty = _preferredSpecialtyController.text.trim();
    if (preferredSpecialty.isNotEmpty && _specialtyFilter == 'All') {
      _specialtyFilter = preferredSpecialty;
    }

    _profileLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _uploadProfilePhoto(BuildContext context, String userId) async {
    if (_isUploadingPhoto) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final uploader = GetIt.instance<UploadAvatarUseCase>();
      final bytes = await picked.readAsBytes();
      final fallbackName = picked.name.trim().isEmpty
          ? 'avatar.jpg'
          : picked.name.trim();
      final url = await uploader(bytes: bytes, fileName: fallbackName);
      _profilePhotoController.text = url;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'photoUrl': url,
        'avatarUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile(BuildContext context, String userId) async {
    final name = _profileNameController.text.trim();
    final phone = _profilePhoneController.text.trim();
    final address = _profileAddressController.text.trim();
    final dob = _profileDobController.text.trim();
    final photo = _profilePhotoController.text.trim();
    final defaultPreferredSpecialty = _preferredSpecialtyController.text.trim();
    final maxDistanceKm = max(
      0,
      _readInt(_maxDistanceController.text.trim(), 20),
    );
    final preferredDurationMinutes = max(
      0,
      _readInt(_preferredDurationController.text.trim(), 30),
    );

    final payload = <String, dynamic>{
      if (name.isNotEmpty) 'displayName': name,
      if (phone.isNotEmpty) 'phone': phone,
      if (address.isNotEmpty) 'address': address,
      if (dob.isNotEmpty) 'dateOfBirth': dob,
      if (photo.isNotEmpty) 'photoUrl': photo,
      if (photo.isNotEmpty) 'avatarUrl': photo,
      'privacySettings': {
        'sharePhoneWithDoctors': _sharePhoneWithDoctors,
        'shareProfileImageWithDoctors': _shareProfileImageWithDoctors,
        'profileVisibility': _profileVisibility,
      },
      'bookingPreferences': {
        'defaultPreferredSpecialty': defaultPreferredSpecialty,
        'maxDistanceKm': maxDistanceKm,
        'reminderLeadTime': _reminderLeadTime,
        'preferredAppointmentDurationMinutes': preferredDurationMinutes,
      },
      'notificationSettings': {
        'bookingConfirmations': _notifyBookingConfirmations,
        'bookingReminders': _notifyBookingReminders,
        'cancellationAlerts': _notifyCancellationAlerts,
        'systemAnnouncements': _notifySystemAnnouncements,
      },
      'preferredDoctorIds': _preferredDoctorIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(payload, SetOptions(merge: true));
      if (name.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      }
      if (photo.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(photo);
      }
      if (defaultPreferredSpecialty.isNotEmpty && _specialtyFilter == 'All') {
        setState(() => _specialtyFilter = defaultPreferredSpecialty);
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

  Future<void> _togglePreferredDoctor(
    BuildContext context, {
    required String userId,
    required String doctorId,
    required bool preferred,
  }) async {
    final next = Set<String>.from(_preferredDoctorIds);
    if (preferred) {
      next.add(doctorId);
    } else {
      next.remove(doctorId);
    }

    setState(() {
      _preferredDoctorIds = next;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'preferredDoctorIds': next.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      setState(() {
        if (preferred) {
          _preferredDoctorIds.remove(doctorId);
        } else {
          _preferredDoctorIds.add(doctorId);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save preference: $e')));
    }
  }

  Future<void> _logoutFromSettings(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.landing);
  }

  Future<void> _promptChangePassword(BuildContext rootContext) async {
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

    setState(() => _isAccountActionRunning = true);
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
      if (mounted) setState(() => _isAccountActionRunning = false);
    }
  }
}
