import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/rice_colors.dart';

/// Institutional theme matching rice.edu brand identity.
///
/// Approved Rice University Typefaces:
/// - Primary Display / Serif: Copernicus (Google Font alternate: Cormorant Garamond)
/// - Primary Body / Sans-Serif: Mallory (Google Font alternate: Lato)
class RiceTheme {
  RiceTheme._();

  static const List<String> headingFontFallbacks = [
    'Copernicus',
    'Cormorant Garamond',
    'Georgia',
    'serif',
  ];

  static const List<String> bodyFontFallbacks = [
    'Mallory',
    'Lato',
    'sans-serif',
  ];

  /// Rice-approved serif typeface for headings and display text
  /// (Copernicus / Cormorant Garamond).
  static TextStyle heading({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ).copyWith(fontFamilyFallback: headingFontFallbacks);
  }

  /// Rice-approved sans-serif typeface for body, UI controls, and labels
  /// (Mallory / Lato).
  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.lato(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ).copyWith(fontFamilyFallback: bodyFontFallbacks);
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.latoTextTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.lato().fontFamily,
      fontFamilyFallback: bodyFontFallbacks,
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
        displayLarge: heading(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
          letterSpacing: -0.5,
        ),
        displayMedium: heading(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
        ),
        displaySmall: heading(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: RiceColors.riceBlue,
        ),
        headlineLarge: heading(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
        ),
        headlineMedium: heading(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        headlineSmall: heading(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        titleLarge: body(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: RiceColors.textPrimary,
        ),
        titleMedium: body(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        titleSmall: body(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RiceColors.textPrimary,
        ),
        bodyLarge: body(
          fontSize: 15,
          color: RiceColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: body(
          fontSize: 14,
          color: RiceColors.textSecondary,
          height: 1.4,
        ),
        bodySmall: body(
          fontSize: 12,
          color: RiceColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: body(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: body(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: RiceColors.riceBlue,
        foregroundColor: RiceColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: heading(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: RiceColors.white,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: heading(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: RiceColors.riceBlue,
        ),
        contentTextStyle: body(
          fontSize: 14,
          color: RiceColors.textPrimary,
          height: 1.4,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return RiceColors.riceBlue.withValues(alpha: 0.8);
          }
          if (states.contains(WidgetState.hovered)) {
            return RiceColors.riceBlue.withValues(alpha: 0.6);
          }
          return RiceColors.darkGray.withValues(alpha: 0.35);
        }),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
            return 8.0;
          }
          return 6.0;
        }),
        radius: const Radius.circular(4),
        crossAxisMargin: 2.0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: body(
          fontSize: 14,
          color: RiceColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: body(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: RiceColors.white,
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: RiceColors.riceBlue,
          textStyle: body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiceColors.riceBlue,
          foregroundColor: RiceColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: body(
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
          textStyle: body(
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
        hintStyle: body(
          color: RiceColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: body(
          color: RiceColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: body(
          color: RiceColors.textSecondary,
          fontSize: 12,
        ),
        errorStyle: body(
          color: RiceColors.errorRed,
          fontSize: 12,
        ),
      ),
    );
  }
}
