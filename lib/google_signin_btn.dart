// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:dbs/config/routes.dart';

class GoogleSignInWebButton extends StatefulWidget {
  const GoogleSignInWebButton({super.key});

  @override
  State<GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<GoogleSignInWebButton> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );

  bool _isLoading = false;

  bool _hasProvider(User user, String providerId) {
    return user.providerData.any((p) => p.providerId == providerId);
  }

  Future<void> _maybeLinkPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasGoogle = _hasProvider(user, 'google.com');
    final hasPassword = _hasProvider(user, 'password');
    final email = user.email;

    if (!hasGoogle || hasPassword || email == null || email.isEmpty) return;

    final password = await _promptForPassword(email);
    if (password == null) return;

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password linked. You can now sign in with email and password.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'provider-already-linked' => 'Password is already linked to this account.',
        'email-already-in-use' => 'Email already in use by another account.',
        'weak-password' => 'Password is too weak.',
        'requires-recent-login' => 'Please sign in again and retry.',
        'operation-not-allowed' => 'Email/Password provider is disabled in Firebase Auth.',
        _ => e.message ?? 'Failed to link password.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to link password: $e')));
    }
  }

  Future<String?> _promptForPassword(String email) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    String? error;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set a password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable email login for $email'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: !obscure,
                        onChanged: (v) => setState(() => obscure = !(v ?? false)),
                      ),
                      const Text('Show password'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p1 = passwordController.text;
                    final p2 = confirmController.text;
                    if (p1.length < 6) {
                      setState(() => error = 'Password must be at least 6 characters.');
                      return;
                    }
                    if (p1 != p2) {
                      setState(() => error = 'Passwords do not match.');
                      return;
                    }
                    Navigator.pop(dialogContext, p1);
                  },
                  child: const Text('Link password'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // On web, use Firebase's recommended approach: GoogleAuthProvider with signInWithPopup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // Allow account selection in the popup
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });

        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // For mobile platforms, use the google_sign_in plugin
        GoogleSignInAccount? account = await _googleSignIn.signInSilently();

        account ??= await _googleSignIn.signIn();

        if (account == null) {
          setState(() => _isLoading = false);
          return;
        }

        // Get authentication tokens
        final auth = await account.authentication;

        // Sign in to Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      setState(() => _isLoading = false);

      if (!mounted) return;
      await _maybeLinkPassword();

      // Navigate to auth redirect so the AuthGuard can route by role
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, Routes.authRedirect);

      // Friendly confirmation
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in successfully')));

    } catch (e, st) {
      setState(() => _isLoading = false);
      // Detailed handling for FirebaseAuthException
      if (e is FirebaseAuthException) {
        // ignore: avoid_print
        print('FirebaseAuthException during Google Sign-In: code=${e.code}, message=${e.message}\n$st');
        // ignore: use_build_context_synchronously
        _showErrorDialog(
          title: 'Authentication error',
          message: '(${e.code}) ${e.message ?? e.toString()}',
          suggestion:
              'Check Firebase/GCP OAuth configuration, browser popups/cookies (web), and SHA keys (Android).',
        );
      } else {
        // Generic exception
        // ignore: avoid_print
        print('Google Sign-In failed: $e\n$st');
        // ignore: use_build_context_synchronously
        _showErrorDialog(
          title: 'Sign-In failed',
          message: e.toString(),
          suggestion: 'Try again or check logs for details.',
        );
      }
    }
  }

  void _showErrorDialog({required String title, required String message, String? suggestion}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (suggestion != null) ...[
              const SizedBox(height: 12),
              Text('Suggestion:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(suggestion),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, Routes.splash); // quick jump to splash for debugging
              },
              child: const Text('Open splash'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (kDebugMode) _buildDebugInfo(),
      ],
    );
  }

  Widget _buildDebugInfo() {
    final user = FirebaseAuth.instance.currentUser;

    return ExpansionTile(
      title: const Text('Auth debug'),
      children: [
        ListTile(
          title: const Text('Firebase user'),
          subtitle: Text(user != null ? '${user.uid}\n${user.email}\n${user.displayName}' : 'null'),
        ),
        ListTile(
          title: const Text('GoogleSignIn account (current)'),
          subtitle: FutureBuilder<GoogleSignInAccount?>(
            future: _googleSignIn.signInSilently(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Text('loading...');
              if (!snap.hasData || snap.data == null) return const Text('null');
              final a = snap.data!;
              return Text('${a.id}\n${a.email}\n${a.displayName}');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await _googleSignIn.signOut();
                  setState(() {});
                },
                child: const Text('Sign out'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  // Refresh debug info
                  await _googleSignIn.signOut();
                  await _googleSignIn.signInSilently();
                  setState(() {});
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
