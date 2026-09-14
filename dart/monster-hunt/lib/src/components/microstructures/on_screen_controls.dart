import 'package:flutter/material.dart';

import '../../models/direction.dart';
import '../molecules/d_pad.dart';
import '../molecules/hold_bar.dart';

class OnScreenControls extends StatelessWidget {
  const OnScreenControls({
    super.key,
    required this.drawHeld,
    required this.onDirectionStart,
    required this.onDirectionEnd,
    required this.onDrawChanged,
  });

  final bool drawHeld;
  final ValueChanged<Direction> onDirectionStart;
  final VoidCallback onDirectionEnd;
  final ValueChanged<bool> onDrawChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DPad(onStart: onDirectionStart, onEnd: onDirectionEnd),
        const SizedBox(width: 16),
        Expanded(
          child: HoldBar(held: drawHeld, onChanged: onDrawChanged),
        ),
      ],
    );
  }
}
