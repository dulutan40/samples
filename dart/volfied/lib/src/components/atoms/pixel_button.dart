import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import 'arcade_text.dart';

class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? GameColors.accent : GameColors.panel,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: filled ? GameColors.accent : GameColors.line),
          ),
          child: ArcadeText(
            label,
            color: filled ? GameColors.bg : GameColors.ink,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}
