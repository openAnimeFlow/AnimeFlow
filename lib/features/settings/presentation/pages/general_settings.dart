import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/locale_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralSettingsPage extends ConsumerStatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  ConsumerState<GeneralSettingsPage> createState() =>
      _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends ConsumerState<GeneralSettingsPage> {
  bool _isLanguageMenuOpen = false;

  _LanguageOption _languageForLocale(Locale locale) {
    if (locale.languageCode == 'en') {
      return _LanguageOption.english;
    }
    if (locale.scriptCode == 'Hant' && locale.countryCode == 'HK') {
      return _LanguageOption.traditionalChineseHongKong;
    }
    if (locale.scriptCode == 'Hant' && locale.countryCode == 'TW') {
      return _LanguageOption.traditionalChineseTaiwan;
    }
    return _LanguageOption.simplifiedChinese;
  }

  void _setLanguage(_LanguageOption language) {
    ref.read(localeProvider.notifier).setLocale(language.locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedLanguage = _languageForLocale(ref.watch(localeProvider));
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.generalSettingsTitle),
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
              title: Text(l10n.languageLabel),
              trailing: DropDownMenu<_LanguageOption>(
                items: _LanguageOption.values,
                selectedItem: selectedLanguage,
                tooltip: l10n.selectLanguageTooltip,
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
                        selectedLanguage.label(l10n),
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
                      Text(language.label(l10n)),
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
  english,
  simplifiedChinese,
  traditionalChineseTaiwan,
  traditionalChineseHongKong;

  const _LanguageOption();

  String label(AppLocalizations l10n) => switch (this) {
        simplifiedChinese => l10n.simplifiedChinese,
        traditionalChineseTaiwan => l10n.traditionalChineseTaiwan,
        traditionalChineseHongKong => l10n.traditionalChineseHongKong,
        english => l10n.englishLanguage,
      };

  Locale get locale => switch (this) {
        simplifiedChinese => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          ),
        traditionalChineseTaiwan => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'TW',
          ),
        traditionalChineseHongKong => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'HK',
          ),
        english => const Locale('en'),
      };
}
