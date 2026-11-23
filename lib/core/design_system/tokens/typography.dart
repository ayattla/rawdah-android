import 'package:flutter/material.dart';

import 'package:rawdah/core/design_system/tokens/colors.dart';

class RT {
  static TextStyle display(double size, {Color color = RC.ink, FontWeight weight = FontWeight.w800}) =>
      TextStyle(
          fontFamily: 'Baloo',
          fontFamilyFallback: const ['Rubik', 'AmiriQuran'],
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.25);
  static TextStyle body(double size, {Color color = RC.ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
          fontFamily: 'Rubik',
          fontFamilyFallback: const ['AmiriQuran'],
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.45);
}
