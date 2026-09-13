import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/direction.dart';

class KeyboardHook {
  KeyEventResult handle(KeyEvent event) {
    if (_isGameKey(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool get space {
    final logical = HardwareKeyboard.instance.logicalKeysPressed;
    final physical = HardwareKeyboard.instance.physicalKeysPressed;
    return logical.contains(LogicalKeyboardKey.space) ||
        physical.contains(PhysicalKeyboardKey.space);
  }

  Direction? get direction {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (_has(keys, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA)) {
      return Direction.left;
    }
    if (_has(keys, LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)) {
      return Direction.right;
    }
    if (_has(keys, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW)) {
      return Direction.up;
    }
    if (_has(keys, LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)) {
      return Direction.down;
    }
    return null;
  }

  bool _has(Set<LogicalKeyboardKey> keys, LogicalKeyboardKey a, LogicalKeyboardKey b) {
    return keys.contains(a) || keys.contains(b);
  }

  bool _isGameKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyS;
  }
}
