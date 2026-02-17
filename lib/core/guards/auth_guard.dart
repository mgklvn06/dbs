import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import '../../features/auth/presentation/pages/login_page.dart';
import '../../core/constants/admin_emails.dart';
import '../../core/settings/system_settings_policy.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
// import '../../features/home/presentation/pages/home_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard.dart';
import '../../features/doctor/presentation/pages/doctor_profile_page.dart';

bool _forceLogoutInProgress = false;

class AuthGuard extends StatelessWidget {
  final Widget unauthenticated;
  final Widget authenticated;

  const AuthGuard({super.key, required this.unauthenticated, required this.authenticated});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _GuardLoading();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return unauthenticated;
        }
        final isEmailAdmin = isAdminEmail(user.email);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('settings').doc('system').snapshots(),
          builder: (context, settingsSnap) {
            if (settingsSnap.connectionState == ConnectionState.waiting) {
              return const _GuardLoading();
            }

            final policy = SystemSettingsPolicy.fromMap(settingsSnap.data?.data() ?? <String, dynamic>{});

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _GuardLoading();
                }

                if (snapshot.hasError) {
                  return isEmailAdmin ? const AdminDashboardPage() : const ProfileSetupPage();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return isEmailAdmin ? const AdminDashboardPage() : const ProfileSetupPage();
                }

                final data = snapshot.data!.data();
                final role = data?['role'] as String?;
                final hasAdminFlag = data?['isAdmin'] == true;
                final isAdminAccount = isEmailAdmin || hasAdminFlag || role == 'admin';
                final acceptedTermsVersion = _readInt(data?['acceptedTermsVersion'], 0);
                final lastSignInAt = _readDateTime(user.metadata.lastSignInTime);

                if (policy.shouldForceLogoutSession(
                  isAdmin: isAdminAccount,
                  lastSignInAt: lastSignInAt,
                )) {
                  _triggerForcedLogout();
                  return const _GuardLoading(message: 'Session secured. Please sign in again.');
                }

                if (policy.requiresTermsAcceptance(
                  isAdmin: isAdminAccount,
                  acceptedTermsVersion: acceptedTermsVersion,
                )) {
                  return _TermsAcceptanceGate(
                    userId: user.uid,
                    termsVersion: policy.termsVersion,
                  );
                }

                if (role == null) {
                  return isEmailAdmin ? const AdminDashboardPage() : const ProfileSetupPage();
                }

                switch (role) {
                  case 'admin':
                    return const AdminDashboardPage();
                  case 'doctor':
                    return const DoctorProfilePage();
                  case 'user':
                  case 'patient':
                    return isEmailAdmin ? const AdminDashboardPage() : authenticated;
                  default:
                    return isEmailAdmin ? const AdminDashboardPage() : unauthenticated;
                }
              },
            );
          },
        );
      },
    );
  }
}

class _GuardLoading extends StatelessWidget {
  final String? message;

  const _GuardLoading({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TermsAcceptanceGate extends StatefulWidget {
  final String userId;
  final int termsVersion;

  const _TermsAcceptanceGate({
    required this.userId,
    required this.termsVersion,
  });

  @override
  State<_TermsAcceptanceGate> createState() => _TermsAcceptanceGateState();
}

class _TermsAcceptanceGateState extends State<_TermsAcceptanceGate> {
  bool _saving = false;

  Future<void> _acceptTerms() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'acceptedTermsVersion': widget.termsVersion,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms Update Required'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'The platform terms were updated.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'You must accept Terms v${widget.termsVersion} to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving ? null : _acceptTerms,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept and Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _triggerForcedLogout() {
  if (_forceLogoutInProgress) return;
  _forceLogoutInProgress = true;
  Future<void>(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      _forceLogoutInProgress = false;
    }
  });
}

int _readInt(dynamic raw, int fallback) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
  return null;
}
