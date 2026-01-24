import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: unused_import
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
// ignore: unused_import
import '../../features/home/presentation/pages/home_page.dart';

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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
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
        final role = data?['role'];

        if (role == null) {
          return const ProfileSetupPage();
        }

        switch (role) {
          case 'admin':
          case 'doctor':
          case 'patient':
            return authenticated;
          default:
            return unauthenticated;
        }
      },
    );
  }
}

class FirebaseFirestore {
  FirebaseFirestore._privateConstructor();

  static final FirebaseFirestore instance = FirebaseFirestore._privateConstructor();

  CollectionReference collection(String path) {
    return CollectionReference();
  } 
}

class CollectionReference {
  DocumentReference doc(String id) {
    return DocumentReference();
  }
}

class DocumentReference {
  Future<DocumentSnapshot> get() async {
    // Simulate a network call
    // Return a dummy document snapshot
    return DocumentSnapshot({'role': 'patient'}, true);
  }
}

class DocumentSnapshot {
  final Map<String, dynamic>? _data;
  final bool _exists;

  DocumentSnapshot(this._data, this._exists);

  bool get exists => _exists;

  Map<String, dynamic>? data() => _data;
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
