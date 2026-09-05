import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF315C55);
  static const ink = Color(0xFF152421);
  static const sand = Color(0xFFF4EFE7);
  static const cloud = Color(0xFFF7F8F5);
  static const accent = Color(0xFFE9905B);
  static const ocean = Color(0xFF315C55);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: ocean,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCEBE7),
      onPrimaryContainer: ink,
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE2D0),
      onSecondaryContainer: Color(0xFF522B17),
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: Color(0xFFECEFEA),
      onSurfaceVariant: Color(0xFF65716D),
      outline: Color(0xFFCBD2CE),
      outlineVariant: Color(0xFFE1E6E2),
      error: Color(0xFFB3261E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cloud,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: ink),
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: ink),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: ink),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: ink),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF53605C)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cloud,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
        iconTheme: IconThemeData(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ocean, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE5E9E6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ocean,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE7EBE8), thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
    );
  }
}
