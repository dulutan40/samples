import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import 'arcade_text.dart';

class HoldKey extends StatelessWidget {
  const HoldKey({
    super.key,
    required this.label,
    required this.held,
    required this.onChanged,
  });

  final String label;
  final bool held;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        color: held ? GameColors.trail : GameColors.panel,
        child: ArcadeText(
          label,
          color: held ? GameColors.bg : GameColors.ink,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}
