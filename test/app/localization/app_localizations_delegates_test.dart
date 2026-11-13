import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/widgets.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as flutter_cupertino;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;

const _zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');

void main() {
  // 组件来自独立的 material_ui / cupertino_ui 包，各自定义了同名的本地化类型。
  // 注册 flutter_localizations 的全局代理无法满足这些组件，必须在代理列表中
  // 提供两个包自己的实现，否则运行时会报 “No MaterialLocalizations found”。
  test('delegates cover material_ui/cupertino_ui types for zh_Hans', () {
    final materialDelegates = appLocalizationsDelegates
        .whereType<LocalizationsDelegate<MaterialLocalizations>>()
        .where((delegate) => delegate.isSupported(_zhHans));
    expect(materialDelegates, hasLength(1));

    final cupertinoDelegates = appLocalizationsDelegates
        .whereType<LocalizationsDelegate<CupertinoLocalizations>>()
        .where((delegate) => delegate.isSupported(_zhHans));
    expect(cupertinoDelegates, hasLength(1));
  });

  test('delegates cover Flutter Cupertino for every supported locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final delegates = appLocalizationsDelegates
          .whereType<
              LocalizationsDelegate<flutter_cupertino.CupertinoLocalizations>>()
          .where((delegate) => delegate.isSupported(locale));
      expect(delegates, hasLength(1), reason: '$locale');
    }
  });
}
