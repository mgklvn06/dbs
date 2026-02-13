import 'package:dbs/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            ElevatedButton(
              onPressed: () async {
                // Resolve the doctor document id for the current user, then navigate
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                final did = await _resolveDoctorIdForUser(uid);
                Navigator.pushNamed(context, Routes.doctorAppointments, arguments: did);
              },
              child: const Text('My appointments'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _resolveDoctorIdForUser(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // 1) Try to find a doctor document that uses a userId field
    final byUser = await firestore.collection('doctors').where('userId', isEqualTo: uid).limit(1).get();
    if (byUser.docs.isNotEmpty) return byUser.docs.first.id;

    // 2) Try to match by email
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      final byEmail = await firestore.collection('doctors').where('email', isEqualTo: user!.email).limit(1).get();
      if (byEmail.docs.isNotEmpty) return byEmail.docs.first.id;
    }

    // 3) Try to match by name/displayName
    final disp = user?.displayName;
    if (disp != null && disp.isNotEmpty) {
      final byName = await firestore.collection('doctors').where('name', isEqualTo: disp).limit(1).get();
      if (byName.docs.isNotEmpty) return byName.docs.first.id;
    }

    // Fallback to the user's uid (may or may not correspond to a doctor doc id)
    return uid;
  }
}
