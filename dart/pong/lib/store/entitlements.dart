import 'package:shared_preferences/shared_preferences.dart';

class Entitlements {
  const Entitlements({
    required this.isPremium,
    required this.timerMultiplier,
  });

  final bool isPremium;
  final double timerMultiplier;

  static const free = Entitlements(isPremium: false, timerMultiplier: 1.0);
  static const premium = Entitlements(isPremium: true, timerMultiplier: 0.0);
}

class EntitlementService {
  static const _premiumKey = 'entitlements.premium';

  Future<Entitlements> load() async {
    final prefs = await SharedPreferences.getInstance();
    final premium = prefs.getBool(_premiumKey) ?? false;
    return premium ? Entitlements.premium : Entitlements.free;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }
}

