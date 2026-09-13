import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';

class I18nService {
  static const _collection = 'i18n';

  Future<I18nBundle> load(Locale locale) async {
    final doc = await FirebaseFirestore.instance
        .collection(_collection)
        .doc(locale.languageCode)
        .get();

    final data = doc.data();
    if (data == null) {
      throw StateError('Missing i18n/${locale.languageCode} in Firestore');
    }

    // Accept either:
    // - { strings: { "home.playCpu": "..." } } (flat)
    // - { strings: { home: { playCpu: "..." } } } (nested)
    // - { home: { playCpu: "..." } } (nested at top-level)
    // Firestore treats "a.b" field names as nested maps unless you use FieldPath.
    final raw = (data['strings'] is Map) ? (data['strings'] as Map) : data;
    final strings = _flattenToDotKeys(raw);
    return I18nBundle(
      locale: locale,
      strings: strings.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, String> _flattenToDotKeys(Map raw) {
    final out = <String, String>{};

    void walk(Object? node, String prefix) {
      if (node is Map) {
        for (final entry in node.entries) {
          final key = entry.key?.toString();
          if (key == null || key.isEmpty) continue;
          final nextPrefix = prefix.isEmpty ? key : '$prefix.$key';
          walk(entry.value, nextPrefix);
        }
        return;
      }

      if (node == null) return;
      if (node is Iterable) return; // ignore arrays

      // Accept string/num/bool and stringify them.
      if (node is String || node is num || node is bool) {
        out[prefix] = node.toString();
      }
    }

    walk(raw, '');
    out.remove('');
    return out;
  }
}

