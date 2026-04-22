import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDeep = Color(0xFF080C14);
  static const Color bgCard = Color(0xFF0F1724);
  static const Color bgElevated = Color(0xFF161F30);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = base.colorScheme.copyWith(
      primary: accentBlue,
      secondary: accentBlue,
      surface: bgCard,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDeep,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDeep,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevated,
        contentTextStyle: GoogleFonts.dmSans(color: textPrimary),
      ),
    );
  }
}
