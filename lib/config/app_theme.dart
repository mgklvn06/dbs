// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _ink = Color(0xFF111418);
  static const Color _primary = Color(0xFF1B7D6A);
  static const Color _secondary = Color(0xFFF4A259);
  static const Color _surface = Color(0xFFFAF7F2);
  static const Color _surfaceVariant = Color(0xFFF1ECE5);
  static const Color _background = Color(0xFFF4F1EA);
  static const Color _error = Color(0xFFE0584A);
  static const Color _outline = Color(0xFFD9D2C9);

  static final ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: _primary,
    secondary: _secondary,
    surface: _surface,
    surfaceVariant: _surfaceVariant,
    error: _error,
    outline: _outline,
    onPrimary: Colors.white,
    onSecondary: _ink,
    onSurface: _ink,
    onBackground: _ink,
    onError: Colors.white,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    scaffoldBackgroundColor: _background,
    textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: _ink,
      displayColor: _ink,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _outline.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surfaceVariant,
      labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: _outline.withOpacity(0.6)),
    ),
  );
}
