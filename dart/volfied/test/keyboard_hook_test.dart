import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volfied/src/hooks/keyboard_hook.dart';

void main() {
  KeyDownEvent down(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) {
    return KeyDownEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );
  }

  KeyUpEvent up(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) {
    return KeyUpEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );
  }

  test('space stays held when an arrow is pressed during the hold', () {
    final hook = KeyboardHook();
    hook.handle(down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));
    hook.handle(down(LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight));
    hook.handle(up(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));

    expect(hook.space, isTrue);
  });

  test('releasing space with no arrows stops the hold', () {
    final hook = KeyboardHook();
    hook.handle(down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));
    hook.handle(up(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));

    expect(hook.space, isFalse);
  });

  test('a real space release is applied after the last arrow comes up', () {
    final hook = KeyboardHook(releaseSettleMs: 0);
    hook.handle(down(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));
    hook.handle(down(LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight));
    hook.handle(up(LogicalKeyboardKey.space, PhysicalKeyboardKey.space));
    hook.handle(up(LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight));

    hook.tick();
    expect(hook.space, isFalse);
  });
}
