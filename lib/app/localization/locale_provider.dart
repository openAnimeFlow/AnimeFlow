import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    return _parseLocale(Storage.setting.get(SettingKey.locale));
  }

  void setLocale(Locale locale) {
    state = locale;
    Storage.setting.put(SettingKey.locale, _localeKey(locale));
  }

  static Locale _parseLocale(Object? value) {
    return switch (value) {
      'en' => const Locale('en'),
      'zh-Hant-TW' => const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      'zh-Hant-HK' => const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        ),
      _ => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    };
  }

  static String _localeKey(Locale locale) {
    if (locale.languageCode == 'en') {
      return 'en';
    }
    if (locale.scriptCode == 'Hant' && locale.countryCode == 'HK') {
      return 'zh-Hant-HK';
    }
    if (locale.scriptCode == 'Hant' && locale.countryCode == 'TW') {
      return 'zh-Hant-TW';
    }
    return 'zh-Hans';
  }
}
