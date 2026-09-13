import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../i18n/i18n_service.dart';
import '../i18n/models.dart';

class BootResult {
  const BootResult({
    required this.bundle,
    required this.splashVideoUrl,
  });

  final I18nBundle bundle;
  final String? splashVideoUrl;
}

class BootLoader {
  BootLoader({
    required this.i18nService,
  });

  final I18nService i18nService;

  Future<BootResult> load(Locale locale) async {
    await _ensureAnonymousAuth();

    final splashVideoUrl = await _tryLoadSplashVideoUrl();
    final bundle = await i18nService.load(locale);

    return BootResult(bundle: bundle, splashVideoUrl: splashVideoUrl);
  }

  Future<void> _ensureAnonymousAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;
    await auth.signInAnonymously();
  }

  Future<String?> _tryLoadSplashVideoUrl() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('config').doc('app').get();
      final data = doc.data();
      final url = data?['splashVideoUrl'];
      if (url is String && url.trim().isNotEmpty) return url.trim();
      return null;
    } catch (_) {
      return null;
    }
  }
}

