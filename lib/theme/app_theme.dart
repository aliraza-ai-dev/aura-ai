import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // === DARK THEME (Primary) ===
  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF111827);
  static const darkCard = Color(0xFF1A2236);
  static const darkCardLight = Color(0xFF1F2A42);
  static const darkBorder = Color(0xFF2A3450);

  // === LIGHT THEME ===
  static const lightBg = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardLight = Color(0xFFF0F3F8);
  static const lightBorder = Color(0xFFE2E8F0);

  // === ACCENT COLORS ===
  static const primary = Color(0xFF6C63FF); // Electric Purple
  static const primaryLight = Color(0xFF8B83FF);
  static const secondary = Color(0xFF00D4FF); // Cyan Neon
  static const secondaryLight = Color(0xFF5CE1FF);
  static const accent = Color(0xFFFF6B9D); // Pink Accent
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF5252);

  // === GRADIENT PRESETS ===
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF1A2236)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF1A2236), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === MODEL COLORS ===
  static const claudeColor = Color(0xFFD97757);
  static const gptColor = Color(0xFF10A37F);
  static const geminiColor = Color(0xFF4285F4);
  static const customColor = Color(0xFFE040FB);
  static const dalleColor = Color(0xFFFF6B9D);
}

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.spaceMono(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white.withOpacity(0.9),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.darkBorder,
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.spaceMono(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A2E),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF1A1A2E).withOpacity(0.9),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF1A1A2E).withOpacity(0.7),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF1A1A2E).withOpacity(0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: const Color(0xFF1A1A2E).withOpacity(0.3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black38,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: AppColors.lightBorder,
      iconTheme: const IconThemeData(color: Color(0xFF4A5568)),
    );
  }
}
