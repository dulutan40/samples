// Generates marketing-style PNG frames for store listings (replace with real
// captures from the running app when UI is final). Run from repo root:
//   dart run tool/gen_store_screenshots.dart

import 'dart:io';

import 'package:image/image.dart';

final _navy = ColorRgb8(15, 23, 42);
final _cyan = ColorRgb8(34, 211, 238);
final _magenta = ColorRgb8(232, 121, 249);
final _white = ColorRgb8(248, 250, 252);
final _slateLine = ColorRgb8(30, 41, 59);

void main() {
  final root = Directory.current;
  final base = Directory('${root.path}/store_assets/screenshots');
  if (!base.existsSync()) {
    base.createSync(recursive: true);
  }

  final specs = <_Spec>[
    _Spec('iphone_6_7', 1290, 2796),
    _Spec('ipad_12_9', 2048, 2732),
    _Spec('mac_16_10', 2560, 1600),
    _Spec('android_phone', 1080, 1920),
  ];

  final scenes = <_Scene>[
    _Scene('01_home', 'Home', 'Main menu & modes'),
    _Scene('02_match', 'Match', 'Rally & score'),
    _Scene('03_powerup', 'Power-ups', 'Modifiers in play'),
    _Scene('04_online', 'Online', 'Head-to-head lobby'),
    _Scene('05_profile', 'Progress', 'Badges & streaks'),
  ];

  for (final spec in specs) {
    final dir = Directory('${base.path}/${spec.folder}');
    dir.createSync(recursive: true);
    for (final scene in scenes) {
      final img = _frame(spec.width, spec.height, scene);
      final path = '${dir.path}/${scene.file}.png';
      File(path).writeAsBytesSync(encodePng(img));
      stdout.writeln('Wrote $path');
    }
  }
}

class _Spec {
  const _Spec(this.folder, this.width, this.height);
  final String folder;
  final int width;
  final int height;
}

class _Scene {
  const _Scene(this.file, this.title, this.subtitle);
  final String file;
  final String title;
  final String subtitle;
}

Image _frame(int w, int h, _Scene scene) {
  final im = Image(width: w, height: h);
  fill(im, color: _navy);

  for (var y = 0; y < h; y += 4) {
    drawLine(
      im,
      x1: 0,
      y1: y,
      x2: w - 1,
      y2: y,
      color: _slateLine,
      thickness: 1,
    );
  }

  final cx = (w * 0.5).round();
  final cy = (h * 0.42).round();
  final ballR = (w * 0.018).round().clamp(8, 36);
  fillCircle(im, x: cx, y: cy, radius: ballR, color: _magenta);

  final paddleW = (w * 0.02).round().clamp(6, 24);
  final paddleH = (h * 0.12).round().clamp(40, 200);
  fillRect(
    im,
    x1: (w * 0.12).round(),
    y1: cy - paddleH ~/ 2,
    x2: (w * 0.12).round() + paddleW,
    y2: cy + paddleH ~/ 2,
    color: _cyan,
  );
  fillRect(
    im,
    x1: (w * 0.86).round(),
    y1: cy - paddleH ~/ 2,
    x2: (w * 0.86).round() + paddleW,
    y2: cy + paddleH ~/ 2,
    color: _cyan,
  );

  drawString(
    im,
    scene.title,
    font: arial48,
    x: (w * 0.08).round(),
    y: (h * 0.12).round(),
    color: _white,
  );
  drawString(
    im,
    scene.subtitle,
    font: arial24,
    x: (w * 0.08).round(),
    y: (h * 0.12 + 56).round(),
    color: _cyan,
  );
  drawString(
    im,
    'Pong',
    font: arial24,
    x: (w * 0.08).round(),
    y: (h * 0.88).round(),
    color: ColorRgb8(100, 116, 139),
  );

  return im;
}
