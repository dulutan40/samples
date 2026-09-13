import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../ads/ads.dart';
import '../firebase_options.dart';
import '../ui/app_root.dart';

class AppStartup {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final ads = _selectAdsService();
    await ads.initialize();

    runApp(const AppRoot());
  }

  static AdsService _selectAdsService() {
    try {
      // Ads are scaffolded; avoid crashing debug builds (especially iOS simulator)
      // when AdMob isn't configured yet.
      final enableAds = const bool.fromEnvironment('ENABLE_ADS', defaultValue: false);
      final isDebug = !kReleaseMode;
      return MobileAdsService(enabled: enableAds && !isDebug);
    } catch (_) {
      return NoopAdsService();
    }
  }
}

