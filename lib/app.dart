import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/routes.dart';
import 'config/app_theme.dart';
// import 'features/auth/presentation/pages/splash_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final uid = authSnapshot.data?.uid;
        if (uid == null) {
          return _buildMaterialApp(ThemeMode.system);
        }

        return StreamBuilder<ThemeMode>(
          stream: _themeModeStream(uid),
          initialData: ThemeMode.system,
          builder: (context, themeSnapshot) {
            return _buildMaterialApp(themeSnapshot.data ?? ThemeMode.system);
          },
        );
      },
    );
  }

  Stream<ThemeMode> _themeModeStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => _resolveThemeMode(snapshot.data()))
        .distinct();
  }

  MaterialApp _buildMaterialApp(ThemeMode mode) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      initialRoute: Routes.splash,
      routes: Routes.pages,
    );
  }

  ThemeMode _resolveThemeMode(Map<String, dynamic>? userSettings) {
    final userMode = _normalizeMode(_readThemeModeValue(userSettings));
    return userMode ?? ThemeMode.system;
  }

  String _readThemeModeValue(Map<String, dynamic>? settings) {
    if (settings == null) return '';
    final appearance = _readMap(settings['appearance']);
    return '${appearance['themeMode'] ?? settings['themeMode'] ?? ''}'
        .trim()
        .toLowerCase();
  }

  ThemeMode? _normalizeMode(String raw) {
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'dark') return ThemeMode.dark;
    if (raw == 'system') return ThemeMode.system;
    return null;
  }

  Map<String, dynamic> _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }
}
