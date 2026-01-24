import 'package:dbs/features/auth/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';

import '../core/guards/auth_guard.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
// ignore: unused_import
import '../features/profile/presentation/pages/profile_setup_page.dart';
import '../features/home/presentation/pages/home_page.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const authRedirect = '/auth';
  static const home = '/home';

  static final Map<String, WidgetBuilder> pages = {
    splash: (_) => const SplashPage(),
    login: (_) => LoginPage(),
    register: (_) => RegisterPage(),

    authRedirect: (_) => AuthGuard(
          unauthenticated: LoginPage(),
          authenticated: HomePage(),
        ),

    home: (_) => HomePage(),
  };

  // static String? get splash => null;
}
