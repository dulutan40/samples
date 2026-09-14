import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../net/online_session.dart';
import '../theme/ltt_theme.dart';
import '../widgets/tap_pad.dart';

class OnlineEntryScreen extends StatefulWidget {
  const OnlineEntryScreen({super.key});

  @override
  State<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends State<OnlineEntryScreen> {
  final _name = TextEditingController(text: 'Player');
  final _room = TextEditingController();
  final _server = TextEditingController(text: defaultServerUrl());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _go({required bool create}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = OnlineSession(serverUrl: _server.text.trim());
    try {
      if (create) {
        await session.create(name: _name.text);
      } else {
        if (_room.text.trim().isEmpty) {
          throw Exception('Enter a room code');
        }
        await session.join(name: _name.text, roomCode: _room.text);
      }
      // Wait briefly for welcome/error
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      if (session.error != null && session.room == null) {
        throw Exception(session.error);
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OnlineRoomScreen(session: session),
        ),
      );
    } catch (e) {
      await session.disposeSocket();
      session.dispose();
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Online', style: GoogleFonts.bebasNeue(fontSize: 28)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _field('Your name', _name),
          const SizedBox(height: 12),
          _field('Server', _server),
          const SizedBox(height: 12),
          _field('Room code (to join)', _room, textCapitalization: TextCapitalization.characters),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: LttColors.coral)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : () => _go(create: true),
            style: FilledButton.styleFrom(
              backgroundColor: LttColors.signal,
              foregroundColor: LttColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Create room'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => _go(create: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: LttColors.cream,
              side: const BorderSide(color: LttColors.stroke),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Join room'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: c,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: LttColors.panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class OnlineRoomScreen extends StatefulWidget {
  const OnlineRoomScreen({super.key, required this.session});

  final OnlineSession session;

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onUpdate);
    widget.session.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final onCooldown = s.you['onCooldown'] == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Room ${s.room ?? "…"}',
          style: GoogleFonts.bebasNeue(fontSize: 28),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.error!, style: const TextStyle(color: LttColors.coral)),
              ),
            Text(
              _phaseLabel(s.phase),
              style: GoogleFonts.bebasNeue(
                fontSize: 42,
                color: LttColors.signal,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.players.map((p) {
                final tapped = p['hasTapped'] == true;
                final you = p['id'] == s.playerId;
                return Chip(
                  label: Text(
                    '${p['name']}${you ? ' (you)' : ''}${tapped && s.phase == 'playing' ? ' · tapped' : ''}',
                  ),
                  backgroundColor: tapped
                      ? LttColors.coral.withValues(alpha: 0.25)
                      : LttColors.panel,
                );
              }).toList(),
            ),
            const Spacer(),
            if (s.phase == 'playing')
              TapPad(
                enabled: !onCooldown,
                label: onCooldown ? 'COOLDOWN' : 'TAP',
                onTap: s.tap,
              )
            else if (s.phase == 'results')
              _Results(
                winnerName: () {
                  for (final p in s.players) {
                    if (p['id'] == s.winnerId) return p['name'] as String?;
                  }
                  return null;
                }(),
                isHost: s.isHost,
                onAgain: s.again,
              )
            else
              Column(
                children: [
                  Text(
                    s.isHost
                        ? 'Start when everyone is ready (2+ players).'
                        : 'Waiting for host to start…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: LttColors.muted),
                  ),
                  const SizedBox(height: 16),
                  if (s.isHost)
                    FilledButton(
                      onPressed: s.start,
                      style: FilledButton.styleFrom(
                        backgroundColor: LttColors.signal,
                        foregroundColor: LttColors.ink,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Start round'),
                    ),
                ],
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(String phase) => switch (phase) {
        'playing' => 'LIVE',
        'results' => 'TIME',
        _ => 'LOBBY',
      };
}

class _Results extends StatelessWidget {
  const _Results({
    required this.winnerName,
    required this.isHost,
    required this.onAgain,
  });

  final String? winnerName;
  final bool isHost;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          winnerName == null ? 'NO ONE TAPPED' : '${winnerName!.toUpperCase()} WINS',
          textAlign: TextAlign.center,
          style: GoogleFonts.bebasNeue(
            fontSize: 40,
            color: winnerName == null ? LttColors.muted : LttColors.mint,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Last legal tap before the hidden cutoff.',
          style: TextStyle(color: LttColors.muted),
        ),
        const SizedBox(height: 20),
        if (isHost)
          FilledButton(
            onPressed: onAgain,
            style: FilledButton.styleFrom(
              backgroundColor: LttColors.signal,
              foregroundColor: LttColors.ink,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Play again'),
          )
        else
          const Text('Waiting for host…', style: TextStyle(color: LttColors.muted)),
      ],
    );
  }
}
