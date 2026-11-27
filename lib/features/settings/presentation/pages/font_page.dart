import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'dart:math' as math;

import 'package:anime_flow/shared/models/font_item.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/features/settings/presentation/widgets/download_mirror_menu.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class FontSettingsPage extends ConsumerStatefulWidget {
  const FontSettingsPage({super.key});

  @override
  ConsumerState<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends ConsumerState<FontSettingsPage> {
  late RulesMirror _mirror = AppSettings.fontRepoMirror;
  bool _savingMirror = false;

  late final FontNetworkTasks _fontNetworkTasks;

  @override
  void initState() {
    super.initState();
    _fontNetworkTasks = ref.read(fontNetworkTasksProvider.notifier);
  }

  @override
  void dispose() {
    _fontNetworkTasks.cancelAll();
    super.dispose();
  }

  Future<void> _refreshFontList() async {
    ref.read(fontNetworkTasksProvider.notifier).cancelAll();
    ref.invalidate(fontProvider);
    try {
      await ref.read(fontProvider.future);
    } catch (_) {}
    if (!mounted) return;
    ref.invalidate(fontPreviewProvider);
    final result = ref.read(fontProvider);
    if (result.hasError) {
      NotificationToast.show(AppLocalizations.of(context)
          .fontRefreshFailed(result.error.toString()));
    }
  }

  Future<void> _selectMirror(RulesMirror mirror) async {
    if (_savingMirror || mirror == _mirror) return;
    setState(() => _savingMirror = true);
    try {
      await AppSettings.setFontRepoMirror(mirror);
      if (!mounted) return;
      _mirror = mirror;
      _fontNetworkTasks.cancelAll();
      ref.invalidate(fontProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _savingMirror = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mirror = _mirror;
    final fontsAsync = ref.watch(fontProvider);
    final selectedFamily = ref.watch(selectedFontProvider);
    final downloadedMetas = ref.watch(downloadedFontMetasProvider);
    ref.watch(fontNetworkTasksProvider);
    final metas = ref.read(downloadedFontMetasProvider.notifier);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final catalogReady =
        fontsAsync.hasValue && !fontsAsync.isLoading && !fontsAsync.hasError;
    final catalog = catalogReady ? fontsAsync.requireValue : <FontItem>[];
    final orphans = metas.orphansFor(catalog.map((font) => font.id).toSet());
    final installed = <FontItem>[];
    final online = <FontItem>[];

    for (final font in catalog) {
      if (ref.watch(fontDownloadProvider(font.id)).status ==
          FontDownloadStatus.done) {
        installed.add(downloadedMetas[font.id] ?? font);
      } else {
        online.add(font);
      }
    }
    if (!catalogReady) {
      installed.addAll(orphans.where((font) =>
          ref.watch(fontDownloadProvider(font.id)).status ==
          FontDownloadStatus.done));
    }

    final currentFont = [
      ...installed,
      ...orphans,
      ...catalog,
    ].where((font) => font.family == selectedFamily).firstOrNull;

    // Keep previews subscribed while their rows are outside the viewport.
    final previews = <String, AsyncValue<String>>{};
    for (final font in [...installed, ...online]) {
      final path = ref.watch(fontDownloadProvider(font.id)).filePath;
      previews[font.id] = ref.watch(fontPreviewProvider((
        fontId: font.id,
        source: path ?? font.preview,
        mirror: path == null ? mirror : null,
      )));
    }

    Widget fontRow(FontItem font, {bool orphan = false}) => _FontListTile(
          key: ValueKey(font.id),
          font: font,
          orphan: orphan,
          preview: previews[font.id],
        );

    return SettingsPageBuilder(
      builder: (context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: SettingsAppBar(
          title: Text(l10n.fontLibrary),
          actions: [
            if (SystemUtil.isDesktop)
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: l10n.refreshFontList,
                onPressed: _refreshFontList,
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = math.max(16.0, (constraints.maxWidth - 920) / 2);
            final topInset = SettingsPageBuilder.topInsetOf(context);
            final textTheme = Theme.of(context).textTheme;
            return RefreshIndicator(
              edgeOffset: topInset,
              onRefresh: _refreshFontList,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  topInset + 16,
                  horizontal,
                  24 + bottomInset,
                ),
                children: [
                  _CurrentFontPanel(
                    name: currentFont?.name ??
                        selectedFamily ??
                        l10n.followSystem,
                    family: selectedFamily,
                    onRestore: () =>
                        ref.read(selectedFontProvider.notifier).clearFont(),
                  ),
                  const SizedBox(height: 24),
                  _FontGroup(
                    title: l10n.downloaded,
                    count: installed.length,
                    children: installed.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l10n.noDownloadedFonts,
                                  style: textTheme.bodySmall),
                            )
                          ]
                        : installed.map(fontRow).toList(),
                  ),
                  const SizedBox(height: 24),
                  _FontGroup(
                    title: l10n.onlineFonts,
                    count: catalogReady ? online.length : null,
                    action: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.fontMirrorLabel,
                          style: textTheme.labelMedium,
                        ),
                        DownloadMirrorMenu(
                          selectedMirror: mirror,
                          tooltip: l10n.fontMirrorLabel,
                          onSelected: _selectMirror,
                          enabled: !_savingMirror,
                        ),
                      ],
                    ),
                    description: mirror == RulesMirror.jsDelivr
                        ? l10n.fontDelayHint
                        : null,
                    children: [
                      if (fontsAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (fontsAsync.hasError)
                        _FontListError(
                          message: fontsAsync.error.toString(),
                          onRetry: () {
                            LiggLogger().e(fontsAsync.error);
                            _refreshFontList();
                          },
                        )
                      else if (online.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(l10n.noOtherFonts,
                              style: textTheme.bodySmall),
                        )
                      else
                        ...online.map(fontRow),
                    ],
                  ),
                  if (catalogReady && orphans.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _FontGroup(
                      title: l10n.downloadedOrphanFonts,
                      count: orphans.length,
                      description: l10n.orphanFontDescription,
                      children: [
                        for (final font in orphans) fontRow(font, orphan: true),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurrentFontPanel extends StatelessWidget {
  const _CurrentFontPanel({
    required this.name,
    required this.family,
    required this.onRestore,
  });

  final String name;
  final String? family;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currentFont,
          style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 4),
        Text(name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(l10n.fontRestartHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant)),
        if (family != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRestore, child: Text(l10n.followSystem)),
        ],
      ],
    );
    final sample = _FontPreviewBox(
      loaded: true,
      failed: false,
      fontFamily: family,
      heading: l10n.currentFontPreview,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 500) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const SizedBox(height: 12), sample],
              );
            }
            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: sample),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FontSectionHeading extends StatelessWidget {
  const _FontSectionHeading({required this.title, this.count, this.action});

  final String title;
  final int? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (count case final value?)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      MaterialLocalizations.of(context).formatDecimal(value),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (action case final widget?) widget,
        ],
      ),
    );
  }
}

class _FontGroup extends StatelessWidget {
  const _FontGroup({
    required this.title,
    this.count,
    this.action,
    this.description,
    required this.children,
  });

  final String title;
  final int? count;
  final Widget? action;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child:
                _FontSectionHeading(title: title, count: count, action: action),
          ),
          if (description case final message?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          Divider(height: 1, color: colors.outlineVariant),
          for (final (index, child) in children.indexed) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            child,
          ],
        ],
      ),
    );
  }
}

class _FontListError extends StatelessWidget {
  const _FontListError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fontListLoadFailed,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _FontListTile extends ConsumerWidget {
  const _FontListTile({
    super.key,
    required this.font,
    required this.preview,
    required this.orphan,
  });

  final FontItem font;
  final AsyncValue<String>? preview;
  final bool orphan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(fontDownloadProvider(font.id));
    final isSelected = ref.watch(selectedFontProvider) == font.family;
    final path = state.filePath;
    final isLocal = state.status == FontDownloadStatus.done;
    final apply = isLocal && path != null && !isSelected
        ? () => ref.read(selectedFontProvider.notifier).selectFont(font, path)
        : null;
    final actions = <Widget>[];

    if (isSelected && (isLocal || orphan)) {
      actions.add(
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              l10n.fontInUse,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
      );
    } else if (apply != null) {
      actions.add(FilledButton.tonal(
        onPressed: apply,
        child: Text(l10n.applyFontAction),
      ));
    }

    if (isLocal || orphan) {
      actions.add(TextButton(
        onPressed: () => _FontDeleteConfirm.show(
          context,
          ref,
          fontId: font.id,
          fontName: font.name,
          isSelected: isSelected,
        ),
        child: Text(l10n.delete),
      ));
    } else if (state.status == FontDownloadStatus.downloading) {
      final percent = (state.progress * 100).toInt();
      actions.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            child: LinearProgressIndicator(
              value: state.progress,
              semanticsLabel: l10n.downloadDownloadingStatus,
            ),
          ),
          const SizedBox(width: 8),
          Text('$percent%', style: theme.textTheme.labelMedium),
        ],
      ));
    } else {
      final failed = state.status == FontDownloadStatus.error;
      if (failed) {
        actions.add(Text(
          l10n.downloadFailed,
          style: theme.textTheme.labelMedium?.copyWith(color: colors.error),
        ));
      }
      actions.add(FilledButton.tonal(
        onPressed: () =>
            ref.read(fontDownloadProvider(font.id).notifier).download(font),
        child: Text(failed ? l10n.retry : l10n.downloadFont),
      ));
    }

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(font.name, style: theme.textTheme.titleSmall),
        const SizedBox(height: 3),
        Text(
          l10n.fontAuthorInfo(font.author, Utils.formatBytes(font.size)),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (orphan && path == null) ...[
          const SizedBox(height: 3),
          Text(
            l10n.orphanFontMissing,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
    final previewState = preview;
    final sample = previewState == null
        ? null
        : _FontPreviewBox(
            loaded: previewState.hasValue,
            failed: previewState.hasError,
            fontFamily: previewState.value,
          );

    return InkWell(
      onTap: apply,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actionBar = Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.end,
              children: actions,
            );
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            if (constraints.maxWidth < 560 * scale) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  if (sample case final widget?) ...[
                    const SizedBox(height: 8),
                    widget,
                  ],
                  const SizedBox(height: 4),
                  actionBar,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: info),
                if (sample case final widget?) ...[
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: widget),
                ],
                const SizedBox(width: 12),
                SizedBox(width: 144 * scale, child: actionBar),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FontDeleteConfirm {
  _FontDeleteConfirm._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String fontId,
    required String fontName,
    required bool isSelected,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).deleteFont),
        content: Text(
          isSelected
              ? AppLocalizations.of(ctx)
                  .deleteSelectedFontConfirmation(fontName)
              : AppLocalizations.of(ctx).deleteFontConfirmation(fontName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx).deleteFont),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(fontDownloadProvider(fontId).notifier).deleteDownload();
    }
  }
}

class _FontPreviewBox extends StatelessWidget {
  const _FontPreviewBox({
    required this.loaded,
    required this.failed,
    this.fontFamily,
    this.heading,
  });

  final bool loaded;
  final bool failed;
  final String? fontFamily;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = heading;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: title == null ? colors.surfaceContainerHigh : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: title == null ? 44 : 98),
        alignment:
            title == null ? Alignment.center : AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: title == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colors.primary)),
              const SizedBox(height: 4),
            ],
            if (failed)
              Text(
                l10n.previewLoadFailed,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              )
            else if (!loaded)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                l10n.fontPreviewHeadline,
                textAlign: title == null ? TextAlign.center : TextAlign.start,
                style: (title == null
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(fontFamily: fontFamily, color: colors.onSurface),
              ),
          ],
        ),
      ),
    );
  }
}
