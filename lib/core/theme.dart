import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const midnight = Color(0xFF0B1020);
  static const ink = Color(0xFF12172A);
  static const violet = Color(0xFF6C5CE7);
  static const cyan = Color(0xFF19C6D1);
  static const coral = Color(0xFFFF8A65);
  static const canvas = Color(0xFFF4F6FB);
  static const soft = Color(0xFFEFF2F8);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: violet,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE9E5FF),
      onPrimaryContainer: Color(0xFF241C66),
      secondary: cyan,
      onSecondary: Color(0xFF04191B),
      secondaryContainer: Color(0xFFDDFBFD),
      onSecondaryContainer: Color(0xFF063A3F),
      tertiary: coral,
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: soft,
      onSurfaceVariant: Color(0xFF626A7D),
      outline: Color(0xFFD2D8E5),
      outlineVariant: Color(0xFFE5E9F1),
      error: Color(0xFFB3261E),
    );

    final text = Typography.material2021().black.apply(
          bodyColor: ink,
          displayColor: ink,
          fontFamily: 'Roboto',
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text.copyWith(
        displaySmall: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.6, color: ink),
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: ink),
        headlineMedium: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -.8, color: ink),
        headlineSmall: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.55, color: ink),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.25, color: ink),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.48, color: Color(0xFF626A7D)),
        bodySmall: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF7A8294)),
        labelLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.35, color: ink),
        iconTheme: IconThemeData(color: ink),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(color: Color(0xFF747C8F), fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: Color(0xFFA0A7B7)),
        prefixIconColor: const Color(0xFF6C5CE7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFE2E6EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFE2E6EF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: violet, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFCE4B55))),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: .96),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: const BorderSide(color: Color(0xFFE6E9F1))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: violet,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFFDCE1EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0xFFE2E6EF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFE9E5FF),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: midnight,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE7EAF1), thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        modalBarrierColor: Color(0x660B1020),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
