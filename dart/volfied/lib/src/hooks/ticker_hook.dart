import 'package:flutter/scheduler.dart';

class TickerHook {
  TickerHook(this.onTick);

  final void Function(Duration elapsed) onTick;
  Ticker? _ticker;
  Duration _last = Duration.zero;

  void start() {
    _ticker ??= Ticker(_handle);
    _last = Duration.zero;
    if (!(_ticker!.isActive)) {
      _ticker!.start();
    }
  }

  void stop() {
    _ticker?.stop();
    _last = Duration.zero;
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }

  void _handle(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    onTick(elapsed - _last);
    _last = elapsed;
  }
}
