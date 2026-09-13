import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../bootstrap/boot_loader.dart';
import '../i18n/app_strings.dart';
import '../i18n/i18n_service.dart';
import '../i18n/keys.dart';
import 'home_screen.dart';
import 'widgets/pong_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplash = Duration(seconds: 2);
  static const _maxNiceSplash = Duration(seconds: 5);

  final _i18nService = I18nService();
  VideoPlayerController? _video;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final startedAt = DateTime.now();

    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final loader = BootLoader(i18nService: _i18nService);
      final result = await loader.load(locale);

      if (!mounted) return;

      if (result.splashVideoUrl != null) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(result.splashVideoUrl!),
        );
        _video = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.play();
      }

      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < _minSplash) {
        await Future<void>.delayed(_minSplash - elapsed);
      } else if (elapsed < _maxNiceSplash) {
        // Let the splash breathe a bit even on fast connections.
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppStrings(
            bundle: result.bundle,
            child: const HomeScreen(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: controller != null && controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PongLogo(size: 140),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() => _error = null);
                          unawaited(_boot());
                        },
                        child: Text(context.t(I18nKeys.retry)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

