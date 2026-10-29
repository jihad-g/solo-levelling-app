import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The dark System look.
class SysColors {
  SysColors._();
  static const ground = Color(0xFF060A13);
  static const panel = Color(0xFF0B1424);
  static const panelEdge = Color(0xFF1C2C47);
  static const cyan = Color(0xFF5CC8FF);
  static const gold = Color(0xFFF0C35A);
  static const purple = Color(0xFFB79BFF);
  static const red = Color(0xFFFF6B78);
  static const text = Color(0xFFE6EEF9);
  static const muted = Color(0xFF8193AE);
}

class AppTheme {
  AppTheme._();

  /// Tests turn this off so google_fonts doesn't try to load fonts.
  static bool useGoogleFonts = true;

  static TextStyle display({
    double size = 20,
    FontWeight weight = FontWeight.w700,
    Color color = SysColors.text,
    double letterSpacing = 1.2,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
    return useGoogleFonts ? GoogleFonts.rajdhani(textStyle: base) : base;
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: SysColors.ground,
      colorScheme: const ColorScheme.dark(
        surface: SysColors.panel,
        primary: SysColors.cyan,
        secondary: SysColors.gold,
        tertiary: SysColors.purple,
        error: SysColors.red,
        onPrimary: SysColors.ground,
        onSurface: SysColors.text,
      ),
    );
    final textTheme = useGoogleFonts
        ? GoogleFonts.ibmPlexSansTextTheme(base.textTheme)
        : base.textTheme;
    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: SysColors.text,
        displayColor: SysColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SysColors.ground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: display(size: 22, color: SysColors.cyan),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SysColors.panel,
        indicatorColor: SysColors.cyan.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          display(size: 13, weight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? SysColors.cyan
                : SysColors.muted,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SysColors.cyan
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(SysColors.ground),
        side: const BorderSide(color: SysColors.cyan, width: 1.5),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        hintStyle: TextStyle(color: Color(0xFF3A4B66)),
        fillColor: SysColors.panel,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: SysColors.panelEdge),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: SysColors.panelEdge),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: SysColors.cyan),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SysColors.cyan,
          foregroundColor: SysColors.ground,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: display(size: 18, color: SysColors.ground),
        ),
      ),
    );
  }
}
