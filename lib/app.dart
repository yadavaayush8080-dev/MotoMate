import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class MotoMateApp extends StatelessWidget {
  const MotoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotoMate',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: AppRoutes.routes,
    );
  }
}