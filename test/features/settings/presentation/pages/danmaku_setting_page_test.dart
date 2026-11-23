import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/features/play/infrastructure/settings/stored_play_preferences.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/settings/presentation/pages/danmaku_setting_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('danmaku_setting_page');
    Hive.init(directory.path);
    Storage.setting = await Hive.openBox<dynamic>(StorageKey.settingsKey);
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('custom danmaku font switch immediately controls menu visibility',
      (tester) async {
    await tester.pumpWidget(_buildSettingsPage());

    final fontSwitch = find.widgetWithText(SwitchListTile, '自定义弹幕字体');
    final fontMenu = find.text('跟随应用字体');
    await tester.ensureVisible(fontSwitch);
    expect(fontMenu, findsOneWidget);

    await tester.runAsync(() => tester.tap(fontSwitch));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(fontSwitch).value, isFalse);
    expect(fontMenu, findsNothing);

    await tester.ensureVisible(fontSwitch);
    await tester.runAsync(() => tester.tap(fontSwitch));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(fontSwitch).value, isTrue);
    expect(fontMenu, findsOneWidget);
    await tester.runAsync(Storage.setting.flush);
  });

  testWidgets('danmaku speed starts at 10% for a saved 0% speed',
      (tester) async {
    await tester.runAsync(
      () => AppSettings.setDanmakuValue(DanmakuKey.danmakuDuration, 16.0),
    );
    await tester.pumpWidget(_buildSettingsPage());

    final l10n = AppLocalizations.of(
      tester.element(find.byType(DanmakuSettingPage)),
    );
    final slider = tester.widget<Slider>(find.byWidgetPredicate(
      (widget) => widget is Slider && widget.label == l10n.danmakuSpeed(10),
    ));
    expect(slider.value, closeTo(10, 0.0001));
    expect(slider.min, 10);
    expect(slider.max, 100);
    expect(slider.divisions, 18);
    expect(AppSettings.danmakuDuration, closeTo(14.6, 0.0001));

    await tester.runAsync(() async {
      slider.onChanged!(15);
      await Storage.setting.flush();
    });
    await tester.pump();
    expect(find.text(l10n.danmakuSpeed(15)), findsOneWidget);
    expect(AppSettings.danmakuDuration, closeTo(13.9, 0.0001));
  });
}

Widget _buildSettingsPage() => ProviderScope(
      overrides: [
        playPreferencesProvider.overrideWith((ref) => StoredPlayPreferences()),
      ],
      child: MaterialApp(
        locale:
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DanmakuSettingPage(),
      ),
    );
