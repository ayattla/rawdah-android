import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/tokens/colors.dart';
import 'package:rawdah/core/design_system/tokens/typography.dart';

ThemeData rawdahTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: RC.green).copyWith(
    primary: RC.green,
    onPrimary: Colors.white,
    secondary: RC.gold,
    tertiary: RC.plum,
    error: RC.coral,
    surface: Colors.white,
    onSurface: RC.ink,
  );
  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Baloo',
    colorScheme: scheme,
    scaffoldBackgroundColor: RC.sand,
    appBarTheme: AppBarTheme(
      backgroundColor: RC.sand,
      foregroundColor: RC.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      // بلا لون حتى يتبع foregroundColor في الأشرطة الداكنة
      titleTextStyle: const TextStyle(
          fontFamily: 'Baloo', fontFamilyFallback: ['Rubik', 'AmiriQuran'], fontSize: 23, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: RC.sandDark)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: RT.display(18, weight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RC.ink,
        side: const BorderSide(color: RC.sandDark, width: 2),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: RT.display(17, weight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: RC.greenDark, textStyle: RT.display(16, weight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.sandDark)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.sandDark)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: RC.green, width: 2)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        selectedBackgroundColor: RC.ink,
        selectedForegroundColor: Colors.white,
        foregroundColor: RC.ink,
        side: const BorderSide(color: RC.sandDark),
        textStyle: RT.display(15, weight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: RC.sandDark),
      labelStyle: RT.body(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? RC.green : null),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFFF7E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Color(0xFF2A1A66), width: 3.5)),
      titleTextStyle: RT.display(22),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A1A66),
      contentTextStyle: RT.display(16, color: const Color(0xFFFFE48A)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFFFD43B), width: 3)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: RC.green, linearTrackColor: RC.sandDark),
    dividerTheme: const DividerThemeData(color: RC.sandDark, thickness: 1),
    listTileTheme: ListTileThemeData(titleTextStyle: RT.display(18, weight: FontWeight.w700), iconColor: RC.green),
  );
}

IconData symbolIcon(String s) {
  switch (s) {
    case 'moon':
      return Icons.nightlight_round;
    case 'sun':
      return Icons.wb_sunny_rounded;
    case 'tree':
      return Icons.park_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'gem':
      return Icons.diamond_rounded;
    default:
      return Icons.star_rounded;
  }
}
