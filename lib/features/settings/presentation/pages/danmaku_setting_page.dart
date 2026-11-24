import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/domain/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/shared/models/font_item.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class DanmakuSettingPage extends ConsumerStatefulWidget {
  const DanmakuSettingPage({super.key});

  @override
  ConsumerState<DanmakuSettingPage> createState() => _DanmakuSettingPageState();
}

class _DanmakuSettingPageState extends ConsumerState<DanmakuSettingPage> {
  // 弹幕配置状态
  late bool _massiveMode;
  late bool _danmakuColor;
  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;
  late bool _platformBilibili;
  late bool _platformGamer;
  late bool _platformDanDanPlay;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _massiveMode = AppSettings.danmakuMassiveMode;
      _danmakuColor = AppSettings.danmakuColor;
      _hideTop = AppSettings.danmakuHideTop;
      _hideBottom = AppSettings.danmakuHideBottom;
      _hideScroll = AppSettings.danmakuHideScroll;
      _platformBilibili = AppSettings.danmakuPlatformBilibili;
      _platformGamer = AppSettings.danmakuPlatformGamer;
      _platformDanDanPlay = AppSettings.danmakuPlatformDanDanPlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paddingOf = MediaQuery.paddingOf(context);
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      child: SettingsPageBuilder(
          builder: (context) => Scaffold(
                extendBodyBehindAppBar: true,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isWideScreen = ref.watch(settingsLayoutProvider);
                      return SettingsAppBar(
                        title: Text(l10n.danmakuSettings),
                        automaticallyImplyLeading: !isWideScreen,
                      );
                    },
                  ),
                ),
                body: SingleChildScrollView(
                  padding: (EdgeInsets.only(
                          left: 10,
                          right: 10 + paddingOf.right,
                          bottom: paddingOf.bottom))
                      .add(EdgeInsets.only(
                          top: SettingsPageBuilder.topInsetOf(context))),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 弹幕显示类型
                          _buildSection(
                            l10n.danmakuDisplayType,
                            [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.scrollingDanmaku),
                                value: !_hideScroll,
                                onChanged: (value) {
                                  setState(() {
                                    _hideScroll = !value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuHideScroll,
                                        _hideScroll);
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.topDanmaku),
                                value: !_hideTop,
                                onChanged: (value) {
                                  setState(() {
                                    _hideTop = !value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuHideTop, _hideTop);
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.bottomDanmaku),
                                value: !_hideBottom,
                                onChanged: (value) {
                                  setState(() {
                                    _hideBottom = !value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuHideBottom,
                                        _hideBottom);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 弹幕来源平台
                          _buildSection(
                            l10n.danmakuSourcePlatform,
                            [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Bilibili'),
                                value: _platformBilibili,
                                onChanged: (value) {
                                  setState(() {
                                    _platformBilibili = value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuPlatformBilibili,
                                        value);
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Gamer'),
                                value: _platformGamer,
                                onChanged: (value) {
                                  setState(() {
                                    _platformGamer = value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuPlatformGamer, value);
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('弹弹Play'),
                                value: _platformDanDanPlay,
                                onChanged: (value) {
                                  setState(() {
                                    _platformDanDanPlay = value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuPlatformDanDanPlay,
                                        value);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 弹幕样式
                          _buildSection(
                            l10n.danmakuStyle,
                            [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.showColor),
                                value: _danmakuColor,
                                onChanged: (value) {
                                  setState(() {
                                    _danmakuColor = value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuColor, _danmakuColor);
                                  });
                                },
                              ),
                              _buildFontControls(l10n),
                              const SizedBox(height: 10),
                              // 简繁转换
                              Consumer(
                                builder: (context, ref, _) {
                                  final danmakuChineseMode =
                                      ref.watch(danmakuChineseModeProvider);
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.danmakuChineseConversion,
                                        ),
                                      ),
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildSelectionMenu(
                                            tooltip:
                                                l10n.danmakuChineseConversion,
                                            options: DanmakuChineseMode.values,
                                            selected: danmakuChineseMode,
                                            label: (mode) {
                                              return switch (mode) {
                                                DanmakuChineseMode.none =>
                                                  l10n.danmakuChineseNone,
                                                DanmakuChineseMode.s2t => l10n
                                                    .danmakuChineseToTraditional,
                                                DanmakuChineseMode.t2s => l10n
                                                    .danmakuChineseToSimplified,
                                              };
                                            },
                                            onSelected: (mode) => ref
                                                .read(danmakuChineseModeProvider
                                                    .notifier)
                                                .setMode(mode),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.massiveMode),
                                value: _massiveMode,
                                onChanged: (value) {
                                  setState(() {
                                    _massiveMode = value;
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuMassiveMode,
                                        _massiveMode);
                                  });
                                },
                              ),
                              Text(
                                l10n.fontStroke,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _DanmakuSlider(
                                initialValue: AppSettings.danmakuStrokeWidth,
                                min: 0,
                                max: 3,
                                divisions: 6,
                                labelBuilder: (value) =>
                                    '${value.toStringAsFixed(1)}px',
                                onChanged: (value) =>
                                    AppSettings.setDanmakuValue(
                                  DanmakuKey.danmakuBorder,
                                  value,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 弹幕速度
                              Text(
                                l10n.danmakuSpeedTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _buildSpeedSlider(l10n),
                              const SizedBox(height: 16),

                              // 透明度
                              Text(
                                l10n.opacity,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _DanmakuSlider(
                                initialValue: AppSettings.danmakuOpacity,
                                min: 0.1,
                                max: 1.0,
                                labelBuilder: (value) =>
                                    '${(value * 100).round()}%',
                                onChanged: (value) =>
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuOpacity, value),
                              ),
                              const SizedBox(height: 16),

                              // 字体大小
                              Text(
                                l10n.fontSize,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _DanmakuSlider(
                                initialValue: AppSettings.danmakuFontSize,
                                min: 12.0,
                                max: 30.0,
                                divisions: 18,
                                labelBuilder: (value) => '${value.toInt()}px',
                                onChanged: (value) =>
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuFontSize, value),
                              ),
                              const SizedBox(height: 16),

                              // 字体粗细
                              Text(
                                l10n.fontWeight,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _DanmakuSlider(
                                initialValue:
                                    AppSettings.danmakuFontWeight.toDouble(),
                                min: 0,
                                max: 8,
                                divisions: 8,
                                labelBuilder: (value) =>
                                    '${(value.round() + 1) * 100}',
                                onChanged: (value) =>
                                    AppSettings.setDanmakuValue(
                                        DanmakuKey.danmakuFontWeight,
                                        value.round()),
                              ),
                              const SizedBox(height: 16),

                              // 显示区域
                              Text(
                                l10n.displayArea,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _buildAreaSlider(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
    );
  }

  Widget _buildFontControls(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, _) {
        final font = ref.watch(danmakuFontSettingsProvider).value ??
            AppSettings.danmakuFont;
        return Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.customDanmakuFont),
              value: font.enabled,
              onChanged: AppSettings.setDanmakuFontEnabled,
            ),
            if (font.enabled) _buildFontMenu(ref, l10n, font.family),
          ],
        );
      },
    );
  }

  Widget _buildFontMenu(
    WidgetRef ref,
    AppLocalizations l10n,
    String? selectedFamily,
  ) {
    final downloadedFonts = ref
        .watch(downloadedFontMetasProvider)
        .values
        .where((font) =>
            ref.watch(fontDownloadProvider(font.id)).status ==
            FontDownloadStatus.done)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final options = [
      const _DanmakuFontOption.project(),
      ...downloadedFonts.map(_DanmakuFontOption.downloaded),
    ];
    final selected = options.firstWhere(
      (option) => option.family == selectedFamily,
      orElse: () => options.first,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: _buildSelectionMenu(
        tooltip: l10n.fontStyle,
        options: options,
        selected: selected,
        label: (option) => option.label(l10n),
        onSelected: (option) => AppSettings.setDanmakuFontFamily(option.family),
      ),
    );
  }

  Widget _buildSpeedSlider(AppLocalizations l10n) {
    final speed = AppSettings.danmakuSpeed;
    return _DanmakuSlider(
      initialValue: speed.percent,
      min: speed.min,
      max: speed.max,
      divisions: speed.divisions,
      labelBuilder: (value) => l10n.danmakuSpeed(value.round()),
      onChanged: (value) => AppSettings.setDanmakuDuration(
        AppSettings.danmakuDurationForSpeed(value),
      ),
    );
  }

  Widget _buildAreaSlider() {
    const fixedValues = [0.1, 0.25, 0.5, 0.75, 1.0];
    var initialIndex = fixedValues.indexWhere(
      (value) => (AppSettings.danmakuArea - value).abs() < 0.01,
    );
    if (initialIndex < 0) initialIndex = 0;
    return _DanmakuSlider(
      initialValue: initialIndex.toDouble(),
      min: 0,
      max: 4,
      divisions: 4,
      labelBuilder: (value) => '${(fixedValues[value.round()] * 100).toInt()}%',
      onChanged: (value) => AppSettings.setDanmakuValue(
        DanmakuKey.danmakuArea,
        fixedValues[value.round()],
      ),
    );
  }

  Widget _buildSelectionMenu<T>({
    required String tooltip,
    required List<T> options,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return JellyMenu<T>(
      tooltip: tooltip,
      trigger: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label(selected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: colors.primary),
          ],
        ),
      ),
      menuBuilder: (context, select) {
        final style = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: colors.onSurface,
          padding: JellyMenu.itemPadding(context),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(6),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  TextButton(
                    style: style,
                    onPressed: option == selected ? null : () => select(option),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: option == selected
                              ? Icon(Icons.check,
                                  size: 18, color: colors.primary)
                              : null,
                        ),
                        Flexible(child: Text(label(option))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      onSelected: onSelected,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _DanmakuSlider extends StatefulWidget {
  const _DanmakuSlider({
    required this.initialValue,
    required this.min,
    required this.max,
    required this.labelBuilder,
    required this.onChanged,
    this.divisions,
  });

  final double initialValue;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) labelBuilder;
  final Future<void> Function(double value) onChanged;

  @override
  State<_DanmakuSlider> createState() => _DanmakuSliderState();
}

class _DanmakuSliderState extends State<_DanmakuSlider> {
  late double _value = widget.initialValue.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final label = widget.labelBuilder(_value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 15),
          child: SizedBox(
            height: kMinInteractiveDimension,
            child: Slider(
              padding: EdgeInsets.zero,
              value: _value,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: label,
              onChanged: (value) {
                setState(() => _value = value);
                widget.onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DanmakuFontOption {
  const _DanmakuFontOption.project() : font = null;

  const _DanmakuFontOption.downloaded(this.font);

  final FontItem? font;

  String? get family => font?.family;

  String label(AppLocalizations l10n) => font?.name ?? l10n.followAppFont;
}
