import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import '../atoms/arcade_text.dart';

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: GameColors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArcadeText(label, size: 11, color: GameColors.muted, letterSpacing: 1.4),
          const SizedBox(height: 4),
          ArcadeText(value, size: 16, color: GameColors.ink),
        ],
      ),
    );
  }
}
