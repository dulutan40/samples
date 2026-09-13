import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/direction.dart';

class KeyboardHook {
  Direction? direction;
  bool space = false;

  KeyEventResult handle(KeyEvent event) {
    final down = event is KeyDownEvent || event is KeyRepeatEvent;
    final pressed = event is! KeyUpEvent;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        direction = pressed ? Direction.left : _clear(Direction.left);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        direction = pressed ? Direction.right : _clear(Direction.right);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        direction = pressed ? Direction.up : _clear(Direction.up);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        direction = pressed ? Direction.down : _clear(Direction.down);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        space = down || (pressed && space);
        if (event is KeyUpEvent) space = false;
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Direction? _clear(Direction released) {
    return direction == released ? null : direction;
  }
}
