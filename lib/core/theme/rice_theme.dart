import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/rice_colors.dart';

/// Institutional theme matching rice.edu brand identity
class RiceTheme {
  RiceTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.latoTextTheme();
    final headingFont = GoogleFonts.cormorantGaramond;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RiceColors.surfaceBackground,
      colorScheme: const ColorScheme.light(
        primary: RiceColors.riceBlue,
        onPrimary: RiceColors.white,
        secondary: RiceColors.riceGray,
        onSecondary: RiceColors.white,
        tertiary: RiceColors.laurelGold,
        surface: RiceColors.surfaceCard,
        onSurface: RiceColors.textPrimary,
        error: RiceColors.errorRed,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headingFont(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
          letterSpacing: -0.5,
        ),
        displayMedium: headingFont(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
        ),
        displaySmall: headingFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: RiceColors.riceBlue,
        ),
        headlineMedium: headingFont(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: RiceColors.textPrimary,
        ),
        titleMedium: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 15,
          color: RiceColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14,
          color: RiceColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RiceColors.riceBlue,
        foregroundColor: RiceColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: RiceColors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: RiceColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: RiceColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiceColors.riceBlue,
          foregroundColor: RiceColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: RiceColors.riceBlue,
          side: const BorderSide(color: RiceColors.riceBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RiceColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.riceBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RiceColors.errorRed),
        ),
        hintStyle: GoogleFonts.lato(
          color: RiceColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.lato(
          color: RiceColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
