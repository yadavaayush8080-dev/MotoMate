import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors (Automotive Sapphire & Cobalt)
  static const Color primary = Color(0xFF1E40AF); // Deep Sapphire
  static const Color primaryDark = Color(0xFF0F172A); // Midnight Slate
  static const Color primaryLight = Color(0xFF3B82F6); // Electric Blue
  static const Color secondary = Color(0xFFF59E0B); // Amber Accent

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean slate tint
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardBg = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status & Emergency Colors
  static const Color emergency = Color(0xFFDC2626); // Emergency Red
  static const Color emergencyLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFF1F5F9);

  // Modern Automotive Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A8A)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const LinearGradient aiSparkleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFDB2777)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );
}