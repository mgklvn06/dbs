import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthDebugPage extends StatefulWidget {
  const AuthDebugPage({super.key});

  @override
  State<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends State<AuthDebugPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile', 'openid']);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Firebase user', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user != null ? '${user.uid}\n${user.email}\n${user.displayName}\n${user.photoURL}' : 'null'),
            const SizedBox(height: 16),
            const Text('GoogleSignIn current account', style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<GoogleSignInAccount?>(
              future: _googleSignIn.signInSilently(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Text('loading...');
                if (!snap.hasData || snap.data == null) return const Text('null');
                final a = snap.data!;
                return Text('${a.id}\n${a.email}\n${a.displayName}');
              },
            ),
            const SizedBox(height: 24),
            Row(
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
                    final acct = await _googleSignIn.signIn();
                    // ignore: avoid_print
                    print('Signed in: ${acct?.email}');
                    setState(() {});
                  },
                  child: const Text('Sign in (interactive)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
