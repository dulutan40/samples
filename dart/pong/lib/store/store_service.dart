import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlements.dart';
import 'products.dart';

class StoreService {
  StoreService({
    InAppPurchase? iap,
    EntitlementService? entitlements,
  })  : _iap = iap ?? InAppPurchase.instance,
        _entitlements = entitlements ?? EntitlementService();

  final InAppPurchase _iap;
  final EntitlementService _entitlements;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(_onPurchases);
  }

  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails({
      StoreProducts.premiumOneTime,
      StoreProducts.streakRepair,
      StoreProducts.premiumSubscriptionMonthly,
    });
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    if (product.id == StoreProducts.streakRepair) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == StoreProducts.premiumOneTime ||
            p.productID == StoreProducts.premiumSubscriptionMonthly) {
          await _entitlements.setPremium(true);
        }

        // streak_repair is consumable; wiring usage comes later.

        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      } else if (p.status == PurchaseStatus.error) {
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
      }
    }
  }
}

