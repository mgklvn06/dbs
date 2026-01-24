import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';

class Routes {
  static const login = '/login';
  static const register = '/register';

  static final Map<String, WidgetBuilder> pages = {
    login: (_) => LoginPage(),
    register: (_) => RegisterPage(),
  };
}
