import 'package:dbs/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'config/routes.dart';
import 'config/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginPage(),
    );
  }
}
