import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/local_engine.dart';
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

  @override
  void initState() {
    super.initState();
    _names = List.generate(8, (i) => TextEditingController(text: 'P${i + 1}'));
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
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
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          for (var i = 0; i < _count; i++) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _names[i],
              decoration: InputDecoration(
                labelText: 'Player ${i + 1}',
                filled: true,
                fillColor: LttColors.panel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final names =
                  List.generate(_count, (i) => _names[i].text.trim()).map((n) {
                return n.isEmpty ? 'Player' : n;
              }).toList();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LocalPlayScreen(names: names),
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
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: LttColors.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tapped
                          ? LttColors.coral.withValues(alpha: 0.7)
                          : LttColors.stroke,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          widget.names[i],
                          style: GoogleFonts.bebasNeue(fontSize: 22),
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
