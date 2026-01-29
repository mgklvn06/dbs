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

        if (account == null) {
          account = await _googleSignIn.signIn();
        }

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

      // Navigate to home
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, Routes.home);

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
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator()
        else
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
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
