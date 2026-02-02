import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color secondary = Color(0xFFEC4899); // Pink
  static const Color accent = Color(0xFF8B5CF6); // Violet

  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800

  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF); // White
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Note Colors
  static const List<Color> noteColors = [
    Color(0xFFFFE4E1), // Misty Rose
    Color(0xFFE0FFFF), // Light Cyan
    Color(0xFFF0FFF0), // Honeydew
    Color(0xFFFFF0F5), // Lavender Blush
    Color(0xFFF5F5DC), // Beige
    Color(0xFFE6E6FA), // Lavender
    Color(0xFFFFFACD), // Lemon Chiffon
    Color(0xFFF0F8FF), // Alice Blue
  ];

  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF22C55E);
}

// Legacy Proxy Class to prevent breaking existing code
class AppColors {
  static const Color primary = AppPalette.primary;
  static const Color secondary = AppPalette.secondary;
  static const Color accent = AppPalette.accent;

  // Deprecated but mapped for compatibility
  static const Color background = AppPalette.darkBackground;
  static const Color surface = AppPalette.darkSurface;
  static const Color surfaceLight = AppPalette.darkSurface;

  static const Color textPrimary = AppPalette.textPrimaryDark;
  static const Color textSecondary = AppPalette.textSecondaryDark;
  static const Color textHint = Colors.grey;
  static const Color textWhite = Colors.white;

  static const LinearGradient primaryGradient = AppPalette.primaryGradient;

  static const List<Color> noteColors = AppPalette.noteColors;
  static const Color priorityHigh = AppPalette.priorityHigh;
  static const Color priorityMedium = AppPalette.priorityMedium;
  static const Color priorityLow = AppPalette.priorityLow;
}

class AppTheme {
  // Common styles
  static final BorderRadius _defaultRadius = BorderRadius.circular(16);
  static const EdgeInsets _defaultPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static TextTheme _buildTextTheme(
    ThemeData base,
    Color primary,
    Color secondary,
  ) {
    return GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primary,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: secondary,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondary,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    Color fillColor,
    Color borderColor,
    Color hintColor,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.outfit(color: hintColor),
      contentPadding: _defaultPadding,
      border: OutlineInputBorder(
        borderRadius: _defaultRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _defaultRadius,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _defaultRadius,
        borderSide: const BorderSide(color: AppPalette.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: _defaultRadius,
        borderSide: const BorderSide(color: AppPalette.error, width: 1.5),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.darkBackground,
      primaryColor: AppPalette.primary,
      cardColor: AppPalette.darkSurface,
      dividerColor: Colors.white.withAlpha(25),
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
        surface: AppPalette.darkSurface,
        error: AppPalette.error,
        onPrimary: Colors.white,
        onSurface: AppPalette.textPrimaryDark,
      ),
      textTheme: _buildTextTheme(
        base,
        AppPalette.textPrimaryDark,
        AppPalette.textSecondaryDark,
      ),
      primaryTextTheme: _buildTextTheme(
        base,
        AppPalette.textPrimaryDark,
        AppPalette.textSecondaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.darkBackground,
        foregroundColor: AppPalette.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppPalette.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: AppPalette.textPrimaryDark),
      ),
      iconTheme: const IconThemeData(color: AppPalette.textPrimaryDark),
      inputDecorationTheme: _buildInputDecorationTheme(
        AppPalette.darkSurface,
        Colors.transparent,
        AppPalette.textSecondaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
          padding: _defaultPadding,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.primary,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textPrimaryDark,
          side: BorderSide(color: AppPalette.textSecondaryDark.withAlpha(50)),
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
          padding: _defaultPadding,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.darkSurface,
        modalBackgroundColor: AppPalette.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppPalette.textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 16,
          color: AppPalette.textSecondaryDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppPalette.darkSurface,
        selectedItemColor: AppPalette.primary,
        unselectedItemColor: AppPalette.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.lightBackground,
      primaryColor: AppPalette.primary,
      cardColor: AppPalette.lightSurface,
      dividerColor: Colors.black.withAlpha(15),
      colorScheme: const ColorScheme.light(
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
        surface: AppPalette.lightSurface,
        error: AppPalette.error,
        onPrimary: Colors.white,
        onSurface: AppPalette.textPrimary,
      ),
      textTheme: _buildTextTheme(
        base,
        AppPalette.textPrimary,
        AppPalette.textSecondary,
      ),
      primaryTextTheme: _buildTextTheme(
        base,
        AppPalette.textPrimary,
        AppPalette.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.lightBackground,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppPalette.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppPalette.textPrimary),
      ),
      iconTheme: const IconThemeData(color: AppPalette.textPrimary),
      inputDecorationTheme: _buildInputDecorationTheme(
        AppPalette.lightSurface,
        Colors.transparent,
        AppPalette.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
          padding: _defaultPadding,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.primary,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textPrimary,
          side: BorderSide(color: AppPalette.textSecondary.withAlpha(50)),
          shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
          padding: _defaultPadding,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.lightSurface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: _defaultRadius),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.lightSurface,
        modalBackgroundColor: AppPalette.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppPalette.textPrimary,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 16,
          color: AppPalette.textSecondary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppPalette.lightSurface,
        selectedItemColor: AppPalette.primary,
        unselectedItemColor: AppPalette.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
