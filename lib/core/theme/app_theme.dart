import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Professional Premium Palette (Zinc/Indigo) ---
  
  // Dark Mode Tokens
  static const Color darkBg = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkPrimary = Color(0xFF6366F1);
  static const Color darkAccent = Color(0xFF818CF8);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextMuted = Color(0xFFA1A1AA);
  
  // Light Mode Tokens
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightPrimary = Color(0xFF4F46E5);
  static const Color lightAccent = Color(0xFF6366F1);
  static const Color lightText = Color(0xFF09090B);
  static const Color lightTextMuted = Color(0xFF71717A);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // --- Legacy Compatibility ---
  static const Color pureWhite = Colors.white;
  static const Color electricBlue = Color(0xFF6366F1);
  static const Color deepSpaceBlue = Color(0xFF09090B);
  static const Color neonCyan = Color(0xFF818CF8);
  static const Color glassBorder = Color(0xFF27272A);
  static const Color glassBackground = Color(0xFF18181B);

  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientEnd = Color(0xFF818CF8);

  static LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient accentGradient = LinearGradient(
    colors: [gradientEnd, gradientStart],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData darkTheme = _buildTheme(Brightness.dark);
  static ThemeData lightTheme = _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    bool isDark = brightness == Brightness.dark;
    Color bg = isDark ? darkBg : lightBg;
    Color surface = isDark ? darkSurface : lightSurface;
    Color primary = isDark ? darkPrimary : lightPrimary;
    Color accent = isDark ? darkAccent : lightAccent;
    Color text = isDark ? darkText : lightText;
    Color textMuted = isDark ? darkTextMuted : lightTextMuted;
    Color border = isDark ? darkBorder : lightBorder;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: text,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: text),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: text),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: text),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: text),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: text),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: text),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
      ).apply(
        bodyColor: text,
        displayColor: text,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: GoogleFonts.poppins(color: text, fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Utility styles ---
  static BoxDecoration glassBox(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        width: 1,
      ),
    );
  }
}
