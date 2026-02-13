// ignore_for_file: deprecated_member_use

import 'package:dbs/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: AppCard(
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 48, child: Icon(Icons.person)),
                      const SizedBox(height: 12),
                      const Text('Dr. John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Cardiology - 10 years experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Resolve the doctor document id for the current user, then navigate
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  final did = await _resolveDoctorIdForUser(uid);
                  // ignore: use_build_context_synchronously
                  Navigator.pushNamed(context, Routes.doctorAppointments, arguments: did);
                },
                child: const Text('My appointments'),
              ),
            ],
          ),
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
