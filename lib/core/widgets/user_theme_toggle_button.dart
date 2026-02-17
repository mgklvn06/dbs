import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserThemeToggleButton extends StatelessWidget {
  final bool showFeedback;

  const UserThemeToggleButton({super.key, this.showFeedback = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => _toggleThemeMode(context, isDark),
    );
  }

  Future<void> _toggleThemeMode(BuildContext context, bool isDark) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nextMode = isDark ? 'light' : 'dark';
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'appearance': {'themeMode': nextMode},
        'themeMode': nextMode,
      }, SetOptions(merge: true));

      if (!context.mounted || !showFeedback) return;
      final label = nextMode == 'dark' ? 'Dark' : 'Light';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Theme set to $label mode')));
    } catch (e) {
      if (!context.mounted || !showFeedback) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update theme: $e')));
    }
  }
}
