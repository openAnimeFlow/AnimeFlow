import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  late _LanguageOption _selectedLanguage;
  bool _isLanguageMenuOpen = false;

  @override
  void initState() {
    super.initState();
    final storedLocale = Storage.setting.get(SettingKey.locale);
    _selectedLanguage = _LanguageOption.values.firstWhere(
      (language) => language.storageValue == storedLocale,
      orElse: () => _LanguageOption.simplifiedChinese,
    );
  }

  void _setLanguage(_LanguageOption language) {
    if (language == _selectedLanguage) return;
    setState(() => _selectedLanguage = language);
    Storage.setting.put(SettingKey.locale, language.storageValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: const Text('通用设置'),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('语言'),
              trailing: DropDownMenu<_LanguageOption>(
                items: _LanguageOption.values,
                selectedItem: _selectedLanguage,
                tooltip: '选择语言',
                onOpenedChanged: (isOpen) {
                  if (_isLanguageMenuOpen == isOpen) return;
                  setState(() => _isLanguageMenuOpen = isOpen);
                },
                buttonBuilder: (context, _) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedLanguage.label,
                        style: TextStyle(color: colorScheme.primary),
                      ),
                      AnimatedRotation(
                        turns: _isLanguageMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
                itemBuilder: (context, language, isSelected) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Text(language.label),
                    ],
                  );
                },
                onSelected: _setLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LanguageOption {
  simplifiedChinese('简体中文', 'zh-Hans'),
  traditionalChineseTaiwan('繁體中文（台灣）', 'zh-Hant-TW'),
  traditionalChineseHongKong('繁體中文（香港）', 'zh-Hant-HK');

  const _LanguageOption(this.label, this.storageValue);

  final String label;
  final String storageValue;
}
