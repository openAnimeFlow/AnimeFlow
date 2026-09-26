import 'dart:io';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/locale_provider.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
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
  late bool _echImageLoading;
  final _echRouteFormKey = GlobalKey<FormState>();
  late final TextEditingController _echHostController;
  final List<TextEditingController> _echIpControllers = [];

  @override
  void initState() {
    super.initState();
    _echImageLoading = AppSettings.echImageLoading;
    _echHostController = TextEditingController(text: AppSettings.echImageHost);
    _echIpControllers.addAll(
      AppSettings.echImageFixedIps.map((ip) => TextEditingController(text: ip)),
    );
  }

  @override
  void dispose() {
    _echHostController.dispose();
    for (final controller in _echIpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEchIp() {
    setState(() => _echIpControllers.add(TextEditingController()));
  }

  void _removeEchIp(TextEditingController controller) {
    setState(() => _echIpControllers.remove(controller));
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

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

  Future<void> _saveEchImageRoute() async {
    if (_echRouteFormKey.currentState?.validate() != true) return;
    await AppSettings.setEchImageRoute(
      host: _echHostController.text,
      fixedIps: AppSettings.parseEchImageFixedIps(
        _echIpControllers.map((controller) => controller.text).join('\n'),
      ),
    );
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _restoreEchImageRoute() async {
    _echRouteFormKey.currentState?.reset();
    _echHostController.text = AppSettings.defaultEchImageHost;
    final removed = _echIpControllers.toList();
    setState(_echIpControllers.clear);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in removed) {
        controller.dispose();
      }
    });
    await AppSettings.setEchImageRoute(
      host: AppSettings.defaultEchImageHost,
    );
    if (mounted) FocusScope.of(context).unfocus();
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
                        selectedLanguage.label,
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
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.image_outlined),
                  title: Text(l10n.echImageLoading),
                  subtitle: Text(l10n.echImageLoadingDescription),
                  value: _echImageLoading,
                  onChanged: (value) async {
                    await AppSettings.setEchImageLoading(value);
                    if (mounted) setState(() => _echImageLoading = value);
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topCenter,
                  child: _echImageLoading
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Form(
                            key: _echRouteFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.echImageRoute,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.echImageRouteHint),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _echHostController,
                                  decoration: InputDecoration(
                                    labelText: l10n.echImageHost,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    return AppSettings.isValidEchImageHost(
                                      value ?? '',
                                    )
                                        ? null
                                        : l10n.echImageInvalidHost;
                                  },
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final fieldWidth =
                                        constraints.maxWidth < 248
                                            ? constraints.maxWidth
                                            : 248.0;
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        for (final controller
                                            in _echIpControllers)
                                          SizedBox(
                                            width: fieldWidth,
                                            child: TextFormField(
                                              key: ValueKey(controller),
                                              controller: controller,
                                              decoration: InputDecoration(
                                                labelText: l10n.echImageFixedIp,
                                                suffixIcon: IconButton(
                                                  tooltip: l10n.delete,
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () =>
                                                      _removeEchIp(controller),
                                                ),
                                              ),
                                              keyboardType: TextInputType.url,
                                              validator: (value) {
                                                final ip = value?.trim() ?? '';
                                                if (ip.isEmpty) {
                                                  return l10n
                                                      .echImageIpRequired;
                                                }
                                                return InternetAddress.tryParse(
                                                          ip,
                                                        ) !=
                                                        null
                                                    ? null
                                                    : l10n.echImageInvalidIp;
                                              },
                                            ),
                                          ),
                                        TextButton.icon(
                                          onPressed: _addEchIp,
                                          icon: const Icon(Icons.add),
                                          label: Text(l10n.echImageAddIp),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _restoreEchImageRoute,
                                      child: Text(l10n.echImageRestoreDefaults),
                                    ),
                                    FilledButton(
                                      onPressed: _saveEchImageRoute,
                                      child: Text(l10n.echImageSave),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.echImageRestartRequired)),
                    ],
                  ),
                ),
              ],
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

  String get label => switch (this) {
        simplifiedChinese => '简体中文',
        traditionalChineseTaiwan => '繁體中文（台灣）',
        traditionalChineseHongKong => '繁體中文（香港）',
        english => 'English',
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
