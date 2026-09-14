import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import '../../helpers/constants.dart';
import '../atoms/arcade_text.dart';
import '../atoms/percent_readout.dart';
import '../molecules/stat_chip.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.percent,
    required this.drawing,
    required this.monsterBig,
  });

  final double percent;
  final bool drawing;
  final bool monsterBig;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PercentReadout(value: percent),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRect(
            child: LinearProgressIndicator(
              value: (percent / GameConstants.winPercent).clamp(0, 1),
              minHeight: 10,
              backgroundColor: GameColors.panel,
              color: GameColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        StatChip(label: 'GOAL', value: '${GameConstants.winPercent.round()}%'),
        const SizedBox(width: 8),
        StatChip(label: 'TRACE', value: drawing ? 'OPEN' : 'SAFE'),
        const SizedBox(width: 8),
        StatChip(label: 'BEAST', value: monsterBig ? 'GIANT' : 'SMALL'),
      ],
    );
  }
}

class GameHudTitle extends StatelessWidget {
  const GameHudTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArcadeText('MONSTER HUNT', size: 18, color: GameColors.accent, letterSpacing: 3);
  }
}
