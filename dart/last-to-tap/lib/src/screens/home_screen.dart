import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ltt_theme.dart';
import 'local_setup_screen.dart';
import 'online_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.15,
            colors: [Color(0xFF1A2230), LttColors.ink],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Text(
                  'LAST TO TAP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 64,
                    height: 0.9,
                    letterSpacing: 2,
                    color: LttColors.cream,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nerve game. Random cutoff between 10–25s.\nLast legal tap wins.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LttColors.muted,
                        height: 1.35,
                      ),
                ),
                const Spacer(flex: 3),
                _ModeButton(
                  label: 'Online room',
                  subtitle: 'Phones, tablets, macOS, web — one room code',
                  accent: LttColors.signal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OnlineEntryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ModeButton(
                  label: 'Local party',
                  subtitle: 'Same screen, one button per player',
                  accent: LttColors.coral,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LocalSetupScreen(),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  '1s cooldown after each tap · no peeking at the clock',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LttColors.muted.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LttColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.55), width: 1.4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.bebasNeue(
                  fontSize: 32,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LttColors.muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
