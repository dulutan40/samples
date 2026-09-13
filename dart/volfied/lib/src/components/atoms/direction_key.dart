import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import '../../models/direction.dart';
import 'arcade_text.dart';

class DirectionKey extends StatelessWidget {
  const DirectionKey({
    super.key,
    required this.direction,
    required this.onStart,
    required this.onEnd,
  });

  final Direction direction;
  final ValueChanged<Direction> onStart;
  final VoidCallback onEnd;

  String get _label {
    return switch (direction) {
      Direction.left => '◀',
      Direction.right => '▶',
      Direction.up => '▲',
      Direction.down => '▼',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onStart(direction),
      onTapUp: (_) => onEnd(),
      onTapCancel: onEnd,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        color: GameColors.panel,
        child: ArcadeText(_label, size: 18, color: GameColors.accent),
      ),
    );
  }
}
