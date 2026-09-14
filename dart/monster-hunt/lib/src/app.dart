import 'package:flutter/material.dart';

import 'helpers/theme.dart';
import 'models/game_status.dart';
import 'screens/home_screen.dart';
import 'screens/play_screen.dart';
import 'screens/result_screen.dart';

class MonsterHuntApp extends StatefulWidget {
  const MonsterHuntApp({super.key});

  @override
  State<MonsterHuntApp> createState() => _MonsterHuntAppState();
}

class _MonsterHuntAppState extends State<MonsterHuntApp> {
  var _screen = _AppScreen.home;
  GameResult? _result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Hunt',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.dark(),
      home: switch (_screen) {
        _AppScreen.home => HomeScreen(onPlay: () => setState(() => _screen = _AppScreen.play)),
        _AppScreen.play => PlayScreen(
            onFinished: (result) {
              setState(() {
                _result = result;
                _screen = _AppScreen.result;
              });
            },
          ),
        _AppScreen.result => ResultScreen(
            result: _result!,
            onRetry: () => setState(() => _screen = _AppScreen.play),
            onHome: () => setState(() => _screen = _AppScreen.home),
          ),
      },
    );
  }
}

enum _AppScreen { home, play, result }
