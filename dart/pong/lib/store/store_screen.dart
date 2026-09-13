import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../i18n/keys.dart';
import 'entitlements.dart';
import 'store_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _store = StoreService();
  final _entitlements = EntitlementService();

  Object? _error;
  bool _loading = true;
  List<dynamic> _products = const [];
  Entitlements _current = Entitlements.free;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.initialize();
      final products = await _store.queryProducts();
      final ent = await _entitlements.load();
      if (!mounted) return;
      setState(() {
        _products = products;
        _current = ent;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t(I18nKeys.navStore))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: Text(context.t(I18nKeys.storePremiumStatus)),
                  subtitle: Text(
                    _current.isPremium
                        ? context.t(I18nKeys.storePremium)
                        : context.t(I18nKeys.storeFree),
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in _products)
                  ListTile(
                    title: Text(p.title.toString()),
                    subtitle: Text(p.description.toString()),
                    trailing: FilledButton(
                      onPressed: () => _store.buy(p),
                      child: Text(p.price.toString()),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _store.restore,
                  child: Text(context.t(I18nKeys.storeRestorePurchases)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error.toString()),
                ],
              ],
            ),
    );
  }
}

