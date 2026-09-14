import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ltt_theme.dart';

class TapPad extends StatelessWidget {
  const TapPad({
    super.key,
    required this.enabled,
    required this.onTap,
    required this.label,
    this.compact = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 120.0 : 220.0;
    return Center(
      child: GestureDetector(
        onTapDown: enabled ? (_) => onTap() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: enabled
                  ? const [Color(0xFFFF6B81), LttColors.coral]
                  : const [Color(0xFF3A4050), Color(0xFF2A3140)],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: LttColors.coral.withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.bebasNeue(
              fontSize: compact ? 36 : 56,
              color: LttColors.cream,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
