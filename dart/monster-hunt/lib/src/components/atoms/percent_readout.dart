import 'package:flutter/material.dart';

import '../../helpers/colors.dart';
import 'arcade_text.dart';

class PercentReadout extends StatelessWidget {
  const PercentReadout({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ArcadeText(
      '${value.toStringAsFixed(1)}%',
      size: 28,
      color: GameColors.accent,
      letterSpacing: 1,
    );
  }
}
