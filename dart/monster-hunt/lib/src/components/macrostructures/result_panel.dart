import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import '../../models/game_status.dart';
import '../atoms/arcade_text.dart';
import '../atoms/percent_readout.dart';
import '../atoms/pixel_button.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onHome,
  });

  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final won = result.status == GameStatus.won;
    return Container(
      width: 420,
      padding: const EdgeInsets.all(28),
      color: GameColors.panel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArcadeText(
            won ? 'FIELD CLAIMED' : 'POISONED',
            size: 28,
            letterSpacing: 3,
            color: won ? GameColors.accent : GameColors.poison,
          ),
          const SizedBox(height: 16),
          PercentReadout(value: result.percent),
          const SizedBox(height: 12),
          ArcadeText(
            won
                ? 'You carved enough of the black field away.'
                : 'The beast touched you or reached you along the trail.',
            align: TextAlign.center,
            weight: FontWeight.w400,
            color: GameColors.muted,
          ),
          const SizedBox(height: 24),
          PixelButton(label: 'PLAY AGAIN', onPressed: onRetry),
          const SizedBox(height: 10),
          PixelButton(label: 'HOME', filled: false, onPressed: onHome),
        ],
      ),
    );
  }
}
