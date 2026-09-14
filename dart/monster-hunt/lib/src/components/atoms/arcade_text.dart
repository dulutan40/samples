import 'package:flutter/material.dart';

import '../../helpers/colors.dart';

class ArcadeText extends StatelessWidget {
  const ArcadeText(
    this.text, {
    super.key,
    this.size = 16,
    this.color = GameColors.ink,
    this.weight = FontWeight.w700,
    this.letterSpacing = 0.4,
    this.align,
  });

  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final double letterSpacing;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
