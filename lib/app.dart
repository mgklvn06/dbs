import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/app_theme.dart';
// import 'features/auth/presentation/pages/splash_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      routes: Routes.pages,
    );
  }
}