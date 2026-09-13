import 'package:flutter/material.dart';

import 'colors.dart';

class GameFonts {
  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
        color: GameColors.ink,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: GameColors.ink,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: GameColors.muted,
      ),
    );
  }
}
