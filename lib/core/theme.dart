import 'package:flutter/material.dart';

import 'design.dart';

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: TripMateColors.navy800,
      onPrimary: Colors.white,
      primaryContainer: TripMateColors.ice,
      onPrimaryContainer: TripMateColors.navy950,
      secondary: TripMateColors.blue600,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDDEEFF),
      onSecondaryContainer: TripMateColors.navy950,
      tertiary: TripMateColors.blue400,
      onTertiary: TripMateColors.navy950,
      surface: Colors.white,
      onSurface: TripMateColors.text,
      surfaceContainerHighest: Color(0xFFEAF2F9),
      onSurfaceVariant: TripMateColors.muted,
      outline: Color(0xFFC9D7E6),
      outlineVariant: Color(0xFFE1EAF2),
      error: Color(0xFFB42318),
    );

    final text = Typography.material2021().black.apply(
          bodyColor: TripMateColors.text,
          displayColor: TripMateColors.text,
          fontFamily: 'Roboto',
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: TripMateColors.canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text.copyWith(
        displaySmall: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.6, color: TripMateColors.text),
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: TripMateColors.text),
        headlineMedium: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -.8, color: TripMateColors.text),
        headlineSmall: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.55, color: TripMateColors.text),
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.25, color: TripMateColors.text),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TripMateColors.text),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: TripMateColors.text),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.48, color: TripMateColors.muted),
        bodySmall: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF8190A8)),
        labelLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.35, color: TripMateColors.text),
        iconTheme: IconThemeData(color: TripMateColors.navy950),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .96),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(color: TripMateColors.muted, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(color: Color(0xFF9AA7B8)),
        prefixIconColor: TripMateColors.blue600,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFDCE6F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFDCE6F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: TripMateColors.blue600, width: 1.8)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: .96),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Color(0xFFE3EBF3))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: TripMateColors.navy800,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: TripMateColors.navy950,
          side: const BorderSide(color: Color(0xFFD7E2EC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0xFFDCE6F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        selectedColor: TripMateColors.ice,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TripMateColors.navy950,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE4EBF2), thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        modalBarrierColor: Color(0x66021024),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
