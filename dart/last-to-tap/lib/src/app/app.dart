import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/home_screen.dart';
import '../theme/ltt_theme.dart';

class LastToTapApp extends StatelessWidget {
  const LastToTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LttColors.ink,
      colorScheme: const ColorScheme.dark(
        primary: LttColors.signal,
        secondary: LttColors.coral,
        surface: LttColors.panel,
      ),
    );

    return MaterialApp(
      title: 'Last to Tap',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
          bodyColor: LttColors.cream,
          displayColor: LttColors.cream,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
