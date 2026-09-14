import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/local_engine.dart';
import '../game/player_names.dart';
import '../theme/ltt_theme.dart';
import '../widgets/tap_pad.dart';

class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  int _count = 4;
  late List<TextEditingController> _names;
  String? _error;

  @override
  void initState() {
    super.initState();
    final defaults = uniqueRandomPlayerNames(8);
    _names = [
      for (final name in defaults) TextEditingController(text: name),
    ];
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _currentNames() =>
      List.generate(_count, (i) => normalizePlayerName(_names[i].text));

  String? _validate() {
    final names = _currentNames();
    for (var i = 0; i < names.length; i++) {
      if (names[i].isEmpty) return 'Every player needs a name';
      if (isPlayerNameTaken(names[i], names, exceptIndex: i)) {
        return 'Name "${names[i]}" is already used';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Local party', style: GoogleFonts.bebasNeue(fontSize: 28)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Players: $_count', style: GoogleFonts.bebasNeue(fontSize: 28)),
          Slider(
            value: _count.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            activeColor: LttColors.coral,
            label: '$_count',
            onChanged: (v) => setState(() {
              _count = v.round();
              _error = _validate();
            }),
          ),
          for (var i = 0; i < _count; i++) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _names[i],
              onChanged: (_) => setState(() => _error = _validate()),
              decoration: InputDecoration(
                labelText: 'Player ${i + 1}',
                filled: true,
                fillColor: LttColors.panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: LttColors.coral)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final err = _validate();
              if (err != null) {
                setState(() => _error = err);
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LocalPlayScreen(names: _currentNames()),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: LttColors.coral,
              foregroundColor: LttColors.cream,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Open table'),
          ),
        ],
      ),
    );
  }
}

class LocalPlayScreen extends StatefulWidget {
  const LocalPlayScreen({super.key, required this.names});

  final List<String> names;

  @override
  State<LocalPlayScreen> createState() => _LocalPlayScreenState();
}

class _LocalPlayScreenState extends State<LocalPlayScreen> {
  late final LocalRoundEngine engine;

  @override
  void initState() {
    super.initState();
    engine = LocalRoundEngine(names: widget.names)..addListener(_tick);
  }

  void _tick() => setState(() {});

  @override
  void dispose() {
    engine
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.names.length <= 3
        ? widget.names.length
        : (widget.names.length <= 4 ? 2 : 2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          switch (engine.phase) {
            LocalPhase.lobby => 'READY',
            LocalPhase.playing => 'LIVE',
            LocalPhase.results => 'TIME',
          },
          style: GoogleFonts.bebasNeue(fontSize: 28, color: LttColors.signal),
        ),
        actions: [
          if (engine.phase != LocalPhase.playing)
            TextButton(
              onPressed: engine.start,
              child: Text(
                engine.phase == LocalPhase.results ? 'AGAIN' : 'START',
                style: const TextStyle(color: LttColors.signal),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (engine.phase == LocalPhase.results)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                engine.winnerIndex == null
                    ? 'NO ONE TAPPED'
                    : '${widget.names[engine.winnerIndex!].toUpperCase()} WINS',
                style: GoogleFonts.bebasNeue(
                  fontSize: 36,
                  color: LttColors.mint,
                ),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: widget.names.length > 4 ? 0.85 : 0.95,
              ),
              itemCount: widget.names.length,
              itemBuilder: (context, i) {
                final cooling = engine.phase == LocalPhase.playing &&
                    engine.onCooldown(i);
                final tapped = engine.lastTap[i] != null;
                final isLast = engine.phase == LocalPhase.playing &&
                    engine.latestTapIndex == i;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: LttColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLast
                          ? LttColors.mint.withValues(alpha: 0.85)
                          : tapped
                              ? LttColors.coral.withValues(alpha: 0.7)
                              : LttColors.stroke,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: widget.names[i],
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 22,
                                  color: LttColors.cream,
                                ),
                              ),
                              if (isLast)
                                TextSpan(
                                  text: ' · last tapped',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: LttColors.mint,
                                  ),
                                )
                              else if (tapped &&
                                  engine.phase == LocalPhase.playing)
                                TextSpan(
                                  text: ' · tapped',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: LttColors.muted,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Expanded(
                          child: TapPad(
                            enabled: engine.phase == LocalPhase.playing &&
                                !cooling,
                            compact: true,
                            label: cooling ? 'WAIT' : 'TAP',
                            onTap: () => engine.tap(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
