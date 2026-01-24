import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

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
              'Upload an avatar and set your name',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () async {
                // Placeholder for Cloudinary upload
              },
              icon: const Icon(Icons.photo_camera),
              label: const Text('Upload avatar'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser!
                    .updateDisplayName('User');

                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Finish setup'),
            ),
          ],
        ),
      ),
    );
  }
}
