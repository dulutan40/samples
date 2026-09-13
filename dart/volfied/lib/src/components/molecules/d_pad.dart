import 'package:flutter/material.dart';

import '../../models/direction.dart';
import '../atoms/direction_key.dart';

class DPad extends StatelessWidget {
  const DPad({
    super.key,
    required this.onStart,
    required this.onEnd,
  });

  final ValueChanged<Direction> onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DirectionKey(direction: Direction.up, onStart: onStart, onEnd: onEnd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DirectionKey(direction: Direction.left, onStart: onStart, onEnd: onEnd),
              DirectionKey(direction: Direction.right, onStart: onStart, onEnd: onEnd),
            ],
          ),
          DirectionKey(direction: Direction.down, onStart: onStart, onEnd: onEnd),
        ],
      ),
    );
  }
}
