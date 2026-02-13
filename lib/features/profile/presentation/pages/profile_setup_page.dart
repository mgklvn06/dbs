// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/constants/admin_emails.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  bool _forceAdmin = false;
  bool _isSaving = false;

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

  Future<void> _finishSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _nameController.text.trim().isEmpty ? user.displayName ?? 'User' : _nameController.text.trim();
    final role = _forceAdmin ? 'admin' : 'user';

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
        'photoUrl': user.photoURL,
        'avatarUrl': user.photoURL,
        'status': 'active',
        'isAdmin': role == 'admin',
        'lastLoginAt': now,
        'updatedAt': now,
      };
      if (!userSnap.exists) userData['createdAt'] = now;
      await userRef.set(userData, SetOptions(merge: true));

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
        automaticallyImplyLeading: false,
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
                      const Icon(Icons.person_outline, size: 72),
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
                        onPressed: () async {
                          // Placeholder for avatar upload (later use UploadAvatarUseCase)
                        },
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Upload avatar (optional)'),
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
            ],
          ),
        ),
      ),
    );
  }
}
