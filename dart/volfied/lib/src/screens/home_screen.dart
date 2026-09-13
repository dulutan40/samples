import 'package:flutter/material.dart';

import '../containers/title_hero.dart';
import '../helpers/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TitleHero(onPlay: onPlay),
          ),
        ),
      ),
    );
  }
}
