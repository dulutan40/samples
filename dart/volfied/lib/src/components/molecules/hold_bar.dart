import 'package:flutter/material.dart';

import '../atoms/hold_key.dart';

class HoldBar extends StatelessWidget {
  const HoldBar({
    super.key,
    required this.held,
    required this.onChanged,
  });

  final bool held;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return HoldKey(label: 'HOLD SPACE', held: held, onChanged: onChanged);
  }
}
