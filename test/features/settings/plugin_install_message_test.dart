import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugin_install_message.dart';
import 'package:anime_flow/features/source/data/repositories/source_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(_zhHans);
  });

  group('插件文案占位符顺序', () {
    // arb 未声明 placeholders 时 gen-l10n 会按字母序生成参数，
    // 与文案阅读顺序不一致，导致调用方把名称和错误对调。
    test('下载/更新失败：名称在前、错误在后', () {
      expect(
        l10n.pluginDownloadFailed('七色动漫', '网络错误'),
        '下载插件 "七色动漫" 时发生错误：网络错误',
      );
      expect(
        l10n.pluginUpdateFailed('七色动漫', '网络错误'),
        '更新插件 "七色动漫" 时发生错误：网络错误',
      );
      expect(
        l10n.pluginCopyFailed('七色动漫', '网络错误'),
        '复制插件 "七色动漫" 失败：网络错误',
      );
    });

    test('版本日期：版本在前、日期在后', () {
      expect(
        l10n.pluginVersionDate('1.0.4', '2026-10-03'),
        '版本：1.0.4 - 2026-10-03',
      );
    });

    test('需要更新客户端提示带插件名', () {
      expect(l10n.pluginRequiresNewerClient('API 源'), contains('API 源'));
    });
  });

  group('pluginInstallErrorMessage', () {
    test('需要更高客户端时给出专用提示，而不是通用失败文案', () {
      const error = PluginInstallException(
        PluginInstallFailure.requiresNewerClient,
        '需要更高版本客户端',
      );

      expect(
        pluginInstallErrorMessage(l10n, 'API 源', error, isUpdate: true),
        l10n.pluginRequiresNewerClient('API 源'),
      );
      expect(
        pluginInstallErrorMessage(l10n, 'API 源', error, isUpdate: false),
        l10n.pluginRequiresNewerClient('API 源'),
      );
    });

    test('规则内容非法时按下载/更新分别给出失败文案', () {
      const error = PluginInstallException(
        PluginInstallFailure.invalidRule,
        '插件配置必须是 JSON 对象',
      );

      expect(
        pluginInstallErrorMessage(l10n, '坏规则', error, isUpdate: false),
        '下载插件 "坏规则" 时发生错误：插件配置必须是 JSON 对象',
      );
      expect(
        pluginInstallErrorMessage(l10n, '坏规则', error, isUpdate: true),
        '更新插件 "坏规则" 时发生错误：插件配置必须是 JSON 对象',
      );
    });

    test('非规则异常走通用失败文案', () {
      final message = pluginInstallErrorMessage(
        l10n,
        '某规则',
        StateError('网络断了'),
        isUpdate: true,
      );

      expect(message, contains('某规则'));
      expect(message, contains('网络断了'));
    });
  });
}
