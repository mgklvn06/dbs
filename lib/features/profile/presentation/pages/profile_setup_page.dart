// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/constants/admin_emails.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _forceAdmin = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _uploadedAvatarUrl;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email;
    _forceAdmin = isAdminEmail(email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final uploader = GetIt.instance<UploadAvatarUseCase>();
      final bytes = await picked.readAsBytes();
      final fallbackName = picked.name.trim().isEmpty ? 'avatar.jpg' : picked.name.trim();
      final url = await uploader(bytes: bytes, fileName: fallbackName);
      _uploadedAvatarUrl = url;
      await user.updatePhotoURL(url);

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        await userRef.set({
          'photoUrl': url,
          'avatarUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar uploaded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _finishSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _nameController.text.trim().isEmpty ? user.displayName ?? 'User' : _nameController.text.trim();
    final role = _forceAdmin ? 'admin' : 'user';
    final photoUrl = _uploadedAvatarUrl ?? user.photoURL;

    setState(() => _isSaving = true);

    try {
      await user.updateDisplayName(displayName);

      final firestore = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      final userRef = firestore.collection('users').doc(user.uid);
      final userSnap = await userRef.get();
      final userData = <String, dynamic>{
        'uid': user.uid,
        'displayName': displayName,
        'role': role,
        'email': user.email,
        'photoUrl': photoUrl,
        'avatarUrl': photoUrl,
        'status': 'active',
        'isAdmin': role == 'admin',
        'lastLoginAt': now,
        'updatedAt': now,
      };
      final existingRole = userSnap.data()?['role'];
      if (!userSnap.exists || existingRole == null) {
        userData['createdAt'] = now;
        await userRef.set(userData, SetOptions(merge: true));
      } else {
        // Only update fields allowed by rules for self-updates.
        await userRef.set({
          'displayName': displayName,
          'photoUrl': user.photoURL,
          'avatarUrl': user.photoURL,
          'lastLoginAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, Routes.admin);
          break;
        case 'doctor':
          Navigator.pushReplacementNamed(context, Routes.doctorProfile);
          break;
        default:
          Navigator.pushReplacementNamed(context, Routes.home);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to save profile: $e');
      final msg = e is FirebaseException
          ? 'Failed to save profile: ${e.code}'
          : 'Failed to save profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final avatarUrl = _uploadedAvatarUrl ?? user?.photoURL;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, Routes.login);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                delay: const Duration(milliseconds: 50),
                child: AppCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                          child: hasAvatar ? null : const Icon(Icons.person_outline, size: 40),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'One last step',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set your display name to personalize your account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Display name'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _forceAdmin ? 'Role: Admin' : 'Role: User',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        icon: _isUploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_camera),
                        label: Text(_isUploadingAvatar ? 'Uploading...' : 'Upload avatar (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _finishSetup,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Finish setup'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, Routes.login);
                },
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
