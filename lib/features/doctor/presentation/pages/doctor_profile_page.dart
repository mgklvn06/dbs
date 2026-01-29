import 'package:flutter/material.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person)),
            const SizedBox(height: 12),
            const Text('Dr. John Doe', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Cardiologist — 10 years experience'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Book appointment')),
          ],
        ),
      ),
    );
  }
}
