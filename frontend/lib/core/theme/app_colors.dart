import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Modern Indigo / Violet SaaS)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF8B5CF6);

  // Status & Score Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Score Gradients
  static const Color scoreHigh = Color(0xFF10B981); // 80 - 100
  static const Color scoreMedium = Color(0xFFF59E0B); // 60 - 79
  static const Color scoreLow = Color(0xFFEF4444); // < 60

  // Light Theme Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Theme Surfaces
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceVariantDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF374151);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
