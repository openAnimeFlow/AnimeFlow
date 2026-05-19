import 'package:anime_flow/models/item/font_item.dart';
import 'package:anime_flow/pages/settings/pages/font/font_provider.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontSettingsPage extends ConsumerStatefulWidget {
  const FontSettingsPage({super.key});

  @override
  ConsumerState<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends ConsumerState<FontSettingsPage> {
  @override
  void dispose() {
    ref.read(fontNetworkTasksProvider.notifier).cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftPadding = MediaQuery.of(context).padding.left;
    final fontsAsync = ref.watch(fontProvider);
    ref.watch(fontNetworkTasksProvider);
    ref.watch(downloadedFontMetasProvider);

    final remoteIds = fontsAsync.maybeWhen(
      data: (fonts) => fonts.map((f) => f.id).toSet(),
      orElse: () => <String>{},
    );
    final orphans =
        ref.read(downloadedFontMetasProvider.notifier).orphansFor(remoteIds);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('字体样式'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.only(
              left: leftPadding == 0 ? 16 : leftPadding,
              right: 16,
              top: 16,
              bottom: 24,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '字体库',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CDN 加速',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: '开启：经 jsDelivr 拉取字体；关闭：直连 GitHub Raw（走镜像）',
                        child: Switch(
                          value: ref.watch(fontRepoCdnProvider),
                          onChanged: (value) => ref
                              .read(fontRepoCdnProvider.notifier)
                              .setEnabled(value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              fontsAsync.when(
                loading: () => const _FontGlassPanel(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _SystemFontListTile(),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => Column(
                  children: [
                    const _FontGlassPanel(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _SystemFontListTile(),
                    ),
                    _FontListError(
                      message: error.toString(),
                      onRetry: () {
                        LiggLogger().e(error);
                        ref.read(fontProvider.notifier).reload();
                      },
                    ),
                  ],
                ),
                data: (fonts) => _FontGlassPanel(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      const _SystemFontListTile(),
                      if (fonts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Text(
                            '暂无其他可用字体',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        )
                      else
                        ...fonts.map((font) => _FontListTile(font: font)),
                    ],
                  ),
                ),
              ),
              if (orphans.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  '本地已下载（远程已下架）',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '以下字体不再出现在远程仓库，但本地仍保留有字体文件。可在此处直接删除或继续应用。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                _FontGlassPanel(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: orphans
                        .map((font) => _OrphanFontListTile(font: font))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FontGlassPanel extends StatelessWidget {
  const _FontGlassPanel({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(24));
    final isDark = SystemUtil.isDarkTheme(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

class _FontListError extends StatelessWidget {
  const _FontListError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            '加载字体列表失败',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _SystemFontListTile extends ConsumerWidget {
  const _SystemFontListTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFamily = ref.watch(selectedFontProvider);
    final isSelected = selectedFamily == null;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      onTap: !isSelected
          ? () => ref.read(selectedFontProvider.notifier).clearFont()
          : null,
      title: Row(
        children: [
          const Expanded(
            child: Text(
              '跟随系统',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: colorScheme.primary),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '使用系统默认字体',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _FontPreviewBox(
            colorScheme: colorScheme,
            loaded: true,
            failed: false,
          ),
        ],
      ),
    );
  }
}

class _FontListTile extends ConsumerWidget {
  const _FontListTile({required this.font});

  final FontItem font;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(fontDownloadProvider(font.id));
    final selectedFamily = ref.watch(selectedFontProvider);
    final isSelected = selectedFamily == font.family;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      onTap: downloadState.status == FontDownloadStatus.done && !isSelected
          ? () => ref
              .read(selectedFontProvider.notifier)
              .selectFont(font, downloadState.filePath!)
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              font.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildActionWidget(
              context, ref, downloadState, isSelected, colorScheme),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '作者：${font.author} - 字体包体积：${FormatTimeUtil.formatBytes(font.size)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          _PreviewFontLoader(
            font: font,
            builder: (context,
                {required loaded, required failed, required family}) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey('preview-${font.id}-$loaded-$failed'),
                  child: _FontPreviewBox(
                    colorScheme: Theme.of(context).colorScheme,
                    loaded: loaded,
                    failed: failed,
                    fontFamily: loaded ? family : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionWidget(
    BuildContext context,
    WidgetRef ref,
    FontDownloadState downloadState,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    switch (downloadState.status) {
      case FontDownloadStatus.idle:
        return IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: '下载字体',
          onPressed: () =>
              ref.read(fontDownloadProvider(font.id).notifier).download(font),
        );

      case FontDownloadStatus.downloading:
        final percent = (downloadState.progress * 100).toInt();
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: downloadState.progress,
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );

      case FontDownloadStatus.done:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              IconButton(
                icon: Icon(Icons.check_circle_rounded,
                    color: colorScheme.primary),
                tooltip: '已应用，点击取消使用',
                onPressed: () =>
                    ref.read(selectedFontProvider.notifier).clearFont(),
              )
            else
              IconButton(
                icon: const Icon(Icons.font_download_outlined),
                tooltip: '点击应用此字体',
                onPressed: () => ref
                    .read(selectedFontProvider.notifier)
                    .selectFont(font, downloadState.filePath!),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除已下载字体',
              onPressed: () => _FontDeleteConfirm.show(
                context,
                ref,
                fontId: font.id,
                fontName: font.name,
                isSelected: isSelected,
              ),
            ),
          ],
        );

      case FontDownloadStatus.error:
        return IconButton(
          icon: Icon(Icons.error_outline, color: colorScheme.error),
          tooltip: '下载失败，点击重试',
          onPressed: () =>
              ref.read(fontDownloadProvider(font.id).notifier).download(font),
        );
    }
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
        title: const Text('删除字体'),
        content: Text(
          isSelected
              ? '将删除「$fontName」的本地文件，并恢复为系统字体，确定继续？'
              : '确定删除「$fontName」的本地字体文件？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(fontDownloadProvider(fontId).notifier).deleteDownload();
    }
  }
}

/// 已下载但已从远程仓库下架的字体条目。
///
/// 只依赖本地缓存的元数据 + 已下载文件，因此即便远程列表完全无法访问，
/// 用户也可以从这里删除或继续应用本地字体。
class _OrphanFontListTile extends ConsumerWidget {
  const _OrphanFontListTile({required this.font});

  final FontItem font;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(fontDownloadProvider(font.id));
    final selectedFamily = ref.watch(selectedFontProvider);
    final isSelected = selectedFamily == font.family;
    final colorScheme = Theme.of(context).colorScheme;
    final hasLocalFile = downloadState.status == FontDownloadStatus.done &&
        downloadState.filePath != null;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      onTap: hasLocalFile && !isSelected
          ? () => ref
              .read(selectedFontProvider.notifier)
              .selectFont(font, downloadState.filePath!)
          : null,
      title: Row(
        children: [
          Expanded(
            child: Text(
              font.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            IconButton(
              icon:
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary),
              tooltip: '已应用，点击取消使用',
              onPressed: () =>
                  ref.read(selectedFontProvider.notifier).clearFont(),
            )
          else if (hasLocalFile)
            IconButton(
              icon: const Icon(Icons.font_download_outlined),
              tooltip: '点击应用此字体',
              onPressed: () => ref
                  .read(selectedFontProvider.notifier)
                  .selectFont(font, downloadState.filePath!),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除已下载字体',
            onPressed: () => _FontDeleteConfirm.show(
              context,
              ref,
              fontId: font.id,
              fontName: font.name,
              isSelected: isSelected,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '作者：${font.author} - 字体包体积：${FormatTimeUtil.formatBytes(font.size)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hasLocalFile ? '远程仓库已下架，仍可继续使用本地字体' : '本地字体文件已丢失，可在此处清理记录',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasLocalFile
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 从 [FontItem.preview] 下载子集 TTF，经 [FontLoader] 注册后供子组件使用。
class _PreviewFontLoader extends ConsumerStatefulWidget {
  const _PreviewFontLoader({
    required this.font,
    required this.builder,
  });

  final FontItem font;
  final Widget Function(
    BuildContext context, {
    required bool loaded,
    required bool failed,
    required String family,
  }) builder;

  @override
  ConsumerState<_PreviewFontLoader> createState() => _PreviewFontLoaderState();
}

class _PreviewFontLoaderState extends ConsumerState<_PreviewFontLoader> {
  bool _loaded = false;
  bool _failed = false;
  CancelToken? _previewCancelToken;

  String get _taskKey => 'preview:${widget.font.id}';

  @override
  void initState() {
    super.initState();
    _loadPreviewFont();
  }

  @override
  void dispose() {
    _previewCancelToken?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PreviewFontLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.font.id != widget.font.id) {
      _loaded = false;
      _failed = false;
      _loadPreviewFont();
    }
  }

  Future<void> _loadPreviewFont() async {
    _previewCancelToken?.cancel();
    final cancelToken = CancelToken();
    _previewCancelToken = cancelToken;
    ref.read(fontNetworkTasksProvider.notifier).register(_taskKey, cancelToken);

    try {
      final bytes = await ref.read(fontProvider.notifier).loadingFont(
            widget.font.preview,
            cancelToken: cancelToken,
          );
      if (bytes.isEmpty) {
        throw StateError('字体预览数据为空');
      }

      final byteData = bytes is Uint8List
          ? ByteData.sublistView(bytes)
          : ByteData.sublistView(Uint8List.fromList(bytes));

      final loader = FontLoader(widget.font.family)
        ..addFont(Future.value(byteData));
      await loader.load();

      if (mounted) {
        setState(() {
          _loaded = true;
          _failed = false;
        });
      }
    } catch (e) {
      if (isFontRequestCancelled(e)) return;
      if (mounted) {
        setState(() {
          _failed = true;
          _loaded = false;
        });
      }
    } finally {
      ref.read(fontNetworkTasksProvider.notifier).unregister(_taskKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fontRepoCdnProvider, (previous, next) {
      if (previous != next && mounted) {
        setState(() {
          _loaded = false;
          _failed = false;
        });
        _loadPreviewFont();
      }
    });
    return widget.builder(
      context,
      loaded: _loaded,
      failed: _failed,
      family: widget.font.family,
    );
  }
}

class _FontPreviewBox extends StatelessWidget {
  const _FontPreviewBox({
    required this.colorScheme,
    required this.loaded,
    required this.failed,
    this.fontFamily,
  });

  final ColorScheme colorScheme;
  final bool loaded;
  final bool failed;
  final String? fontFamily;

  static const headline = '欢迎使用 AnimeFlow';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (failed) {
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.font_download_off_outlined,
              size: 18,
              color: colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              '预览加载失败',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (!loaded) {
      return Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        headline,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
