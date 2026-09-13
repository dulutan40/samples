import 'package:flutter/material.dart';

import 'colors.dart';
import 'fonts.dart';

class GameTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: GameColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: GameColors.accent,
        surface: GameColors.panel,
        onSurface: GameColors.ink,
      ),
      textTheme: GameFonts.textTheme(base.textTheme),
    );
  }
}
