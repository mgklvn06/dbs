import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  String _selectedRole = 'patient';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _nameController.text.trim().isEmpty ? user.displayName ?? 'User' : _nameController.text.trim();

    setState(() => _isSaving = true);

    try {
      await user.updateDisplayName(displayName);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'role': _selectedRole,
        'email': user.email,
        'avatarUrl': user.photoURL,
      }, SetOptions(merge: true));

      // ignore: use_build_context_synchronously
      switch (_selectedRole) {
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
      // ignore: use_build_context_synchronously
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            const Icon(
              Icons.person_outline,
              size: 80,
            ),

            const SizedBox(height: 24),

            const Text(
              'One last step',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Set your display name and role',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
              items: const [
                DropdownMenuItem(value: 'patient', child: Text('Patient')),
                DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              decoration: const InputDecoration(labelText: 'Role'),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                // Placeholder for avatar upload (later use UploadAvatarUseCase)
              },
              icon: const Icon(Icons.photo_camera),
              label: const Text('Upload avatar (optional)'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isSaving ? null : _finishSetup,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Finish setup'),
            ),
          ],
        ),
      ),
    );
  }
}
