import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
// import '../../features/home/presentation/pages/home_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard.dart';
import '../../features/doctor/presentation/pages/doctor_profile_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget unauthenticated;
  final Widget authenticated;

  const AuthGuard({super.key, required this.unauthenticated, required this.authenticated});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return unauthenticated;
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GuardLoading();
        }

        if (snapshot.hasError) {
          return const ProfileSetupPage();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ProfileSetupPage();
        }

        final data = snapshot.data!.data();
        final role = data?['role'] as String?;

        if (role == null) {
          return const ProfileSetupPage();
        }

        switch (role) {
          case 'admin':
            return const AdminDashboardPage();
          case 'doctor':
            return const DoctorProfilePage();
          case 'user':
          case 'patient':
            return authenticated;
          default:
            return unauthenticated;
        }
      },
    );
  }
}

class _GuardLoading extends StatelessWidget {
  const _GuardLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
