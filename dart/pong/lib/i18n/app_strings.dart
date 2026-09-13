import 'package:flutter/material.dart';

import 'i18n_service.dart';
import 'models.dart';
import 'keys.dart';

class AppStrings extends InheritedWidget {
  const AppStrings({
    required this.bundle,
    required super.child,
    super.key,
  });

  final I18nBundle bundle;

  static AppStrings of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppStrings>();
    if (widget == null) {
      throw StateError('AppStrings not found in widget tree');
    }
    return widget;
  }

  String t(String key) => bundle.t(key);

  @override
  bool updateShouldNotify(AppStrings oldWidget) =>
      oldWidget.bundle.strings != bundle.strings ||
      oldWidget.bundle.locale != bundle.locale;
}

class AppStringsHost extends StatefulWidget {
  const AppStringsHost({
    required this.i18nService,
    required this.child,
    super.key,
  });

  final I18nService i18nService;
  final Widget child;

  @override
  State<AppStringsHost> createState() => _AppStringsHostState();
}

class _AppStringsHostState extends State<AppStringsHost> {
  I18nBundle? _bundle;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });

    final locale = Localizations.localeOf(context);
    try {
      final bundle = await widget.i18nService.load(locale);
      if (!mounted) return;
      setState(() => _bundle = bundle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bundle == null) {
      return _I18nLoading(error: _error, onRetry: _load);
    }
    return AppStrings(bundle: _bundle!, child: widget.child);
  }
}

class _I18nLoading extends StatelessWidget {
  const _I18nLoading({
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isFirstLaunchOffline = error != null;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t(I18nKeys.splashLoading)),
              if (isFirstLaunchOffline) ...[
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: Text(context.t(I18nKeys.retry)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension AppStringsContext on BuildContext {
  String t(String key) => AppStrings.of(this).t(key);
}

