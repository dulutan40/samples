import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_service.dart';

class MobileAdsService implements AdsService {
  MobileAdsService({this.enabled = true});

  final bool enabled;

  @override
  Future<void> initialize() async {
    if (!isSupported) return;
    if (!enabled) return;
    await MobileAds.instance.initialize();
  }

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

