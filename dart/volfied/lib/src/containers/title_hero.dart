import 'package:flutter/material.dart';

import '../components/atoms/arcade_text.dart';
import '../components/atoms/pixel_button.dart';
import '../helpers/colors.dart';

class TitleHero extends StatelessWidget {
  const TitleHero({super.key, required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ArcadeText('VOLFIED', size: 56, letterSpacing: 8, color: GameColors.accent),
          const SizedBox(height: 16),
          const ArcadeText(
            'You own the rim. The computer owns the black. Hold space, cut a trail, and close a shape. Keep the snake off your line.',
            align: TextAlign.center,
            weight: FontWeight.w400,
            color: GameColors.muted,
          ),
          const SizedBox(height: 28),
          PixelButton(label: 'ENTER THE FIELD', onPressed: onPlay),
          const SizedBox(height: 18),
          const ArcadeText(
            'Arrows walk the rim. Hold space and press an arrow to cut. Release space to stop cutting — you can walk the rim again or backtrack the trail.',
            size: 13,
            align: TextAlign.center,
            weight: FontWeight.w400,
            color: GameColors.muted,
          ),
        ],
      ),
    );
  }
}
