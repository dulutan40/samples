import 'package:flutter/material.dart';

import '../components/macrostructures/playfield_view.dart';
import '../components/microstructures/game_hud.dart';
import '../components/microstructures/on_screen_controls.dart';
import '../game/world.dart';
import '../helpers/colors.dart';
import '../models/direction.dart';

class PlayStage extends StatelessWidget {
  const PlayStage({
    super.key,
    required this.world,
    required this.showTouchControls,
    required this.drawHeld,
    required this.onDirectionStart,
    required this.onDirectionEnd,
    required this.onDrawChanged,
  });

  final World world;
  final bool showTouchControls;
  final bool drawHeld;
  final ValueChanged<Direction> onDirectionStart;
  final VoidCallback onDirectionEnd;
  final ValueChanged<bool> onDrawChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GameHudTitle(),
        const SizedBox(height: 12),
        GameHud(
          percent: world.percent,
          drawing: world.drawing,
          monsterBig: world.monster.big,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: GameColors.line)),
            child: PlayfieldView(world: world),
          ),
        ),
        if (showTouchControls) ...[
          const SizedBox(height: 16),
          OnScreenControls(
            drawHeld: drawHeld,
            onDirectionStart: onDirectionStart,
            onDirectionEnd: onDirectionEnd,
            onDrawChanged: onDrawChanged,
          ),
        ],
      ],
    );
  }
}
