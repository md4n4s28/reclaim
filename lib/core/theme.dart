import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep Modern Dark Theme Colors
  static const background = Color(0xFF050505);
  static const surface = Color(0xFF0F0F11);
  static const card = Color(0xFF141417);
  static const primary = Color(0xFF4F46E5); // Indigo 600
  static const primaryGlow = Color(0xFF6366F1); // Indigo 500
  static const accent = Color(0xFF10B981); // Emerald 500 (Progress/Success)
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const danger = Color(0xFFEF4444); // Red 500
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF475569);
  static const border = Color(0xFF27272A);
  static const streakOrange = Color(0xFFF97316); // Orange 500
  static const panicRed = Color(0xFFFF3366);

  // Modern Light Theme Colors
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF4F46E5);
  static const lightAccent = Color(0xFF10B981);
  static const lightWarning = Color(0xFFF59E0B);
  static const lightDanger = Color(0xFFEF4444);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFF94A3B8);
  static const lightBorder = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.danger,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          surface: AppColors.lightSurface,
          primary: AppColors.lightPrimary,
          secondary: AppColors.lightAccent,
          error: AppColors.lightDanger,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
            color: AppColors.lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.inter(
            color: AppColors.lightTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.inter(
            color: AppColors.lightTextPrimary,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.inter(
            color: AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.lightBorder, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      );
}
