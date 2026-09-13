import 'package:flutter/material.dart';

import '../components/macrostructures/result_panel.dart';
import '../helpers/colors.dart';
import '../models/game_status.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onHome,
  });

  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      body: SafeArea(
        child: Center(
          child: ResultPanel(result: result, onRetry: onRetry, onHome: onHome),
        ),
      ),
    );
  }
}
