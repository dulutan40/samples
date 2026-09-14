import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../hooks/hold_hook.dart';
import '../hooks/keyboard_hook.dart';
import '../models/direction.dart';

class InputService {
  InputService() {
    HardwareKeyboard.instance.addHandler(_onHardware);
  }

  final KeyboardHook keyboard = KeyboardHook();
  final HoldHook drawHold = HoldHook();
  Direction? _pointerDirection;

  bool get space => keyboard.space || drawHold.held;

  Direction? get direction => _pointerDirection ?? keyboard.direction;

  void tick() => keyboard.tick();

  KeyEventResult onKey(KeyEvent event) => keyboard.handle(event);

  void setPointerDirection(Direction? direction) {
    _pointerDirection = direction;
  }

  void setDrawHeld(bool held) {
    drawHold.set(held);
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardware);
  }

  bool _onHardware(KeyEvent event) {
    return keyboard.handle(event) == KeyEventResult.handled;
  }
}
