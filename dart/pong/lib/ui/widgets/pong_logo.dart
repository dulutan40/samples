import 'package:flutter/material.dart';

class PongLogo extends StatelessWidget {
  const PongLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = size;
    final h = size;

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _PongLogoPainter(
          fg: cs.onSurface,
          accent: cs.primary,
        ),
      ),
    );
  }
}

class _PongLogoPainter extends CustomPainter {
  _PongLogoPainter({required this.fg, required this.accent});

  final Color fg;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.18),
    );
    final bgPaint = Paint()..color = fg.withValues(alpha: 0.08);
    canvas.drawRRect(r, bgPaint);

    final midX = size.width / 2;
    final p = Paint()
      ..color = fg.withValues(alpha: 0.7)
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(midX, size.height * 0.14),
        Offset(midX, size.height * 0.86), p);

    final paddlePaint = Paint()..color = fg.withValues(alpha: 0.9);
    final paddleW = size.width * 0.07;
    final paddleH = size.height * 0.30;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.14, size.height * 0.20, paddleW, paddleH),
        Radius.circular(paddleW),
      ),
      paddlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.79, size.height * 0.50, paddleW, paddleH),
        Radius.circular(paddleW),
      ),
      paddlePaint,
    );

    final ballPaint = Paint()..color = accent;
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.34),
      size.shortestSide * 0.06,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PongLogoPainter oldDelegate) =>
      oldDelegate.fg != fg || oldDelegate.accent != accent;
}

