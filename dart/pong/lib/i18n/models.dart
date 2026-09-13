import 'package:flutter/widgets.dart';

typedef I18nKey = String;

class I18nBundle {
  const I18nBundle({
    required this.locale,
    required this.strings,
  });

  final Locale locale;
  final Map<I18nKey, String> strings;

  String t(I18nKey key) => strings[key] ?? key;
}

