import 'package:anime_flow/models/item/font_item.dart';
import 'package:anime_flow/pages/settings/pages/font/font_provider.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontSettingsPage extends ConsumerWidget {
  const FontSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leftPadding = MediaQuery.of(context).padding.left;
    final fontsAsync = ref.watch(fontProvider);

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
              const Text(
                '字体库',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              fontsAsync.when(
                loading: () => _fontGlassPanel(
                  context,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Column(
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
                    _fontGlassPanel(
                      context,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const _SystemFontListTile(),
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
                data: (fonts) => _fontGlassPanel(
                  context,
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
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fontGlassPanel(
  BuildContext context, {
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  const borderRadius = BorderRadius.all(Radius.circular(24));
  return ClipRRect(
    borderRadius: borderRadius,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SystemUtil.isDarkTheme(context)
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        borderRadius: borderRadius,
        border: Border.all(
          color: SystemUtil.isDarkTheme(context)
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.15),
        ),
      ),
      child: child,
    ),
  );
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

class _SystemFontListTile extends StatelessWidget {
  const _SystemFontListTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        '跟随系统',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
            colorScheme: Theme.of(context).colorScheme,
            loaded: true,
            failed: false,
          )
        ],
      ),
    );
  }
}

class _FontListTile extends StatelessWidget {
  const _FontListTile({required this.font});

  final FontItem font;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            font.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.cloud_download_outlined))
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
          _FontPreviewSnippet(font: font),
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

  @override
  void initState() {
    super.initState();
    _loadPreviewFont();
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
    try {
      final bytes = await ref
          .read(fontProvider.notifier)
          .downloadFont(widget.font.preview);
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

class _FontPreviewSnippet extends StatelessWidget {
  const _FontPreviewSnippet({required this.font});

  final FontItem font;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _PreviewFontLoader(
      font: font,
      builder: (context, {required loaded, required failed, required family}) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey('preview-${font.id}-$loaded-$failed'),
            child: _FontPreviewBox(
              colorScheme: colorScheme,
              loaded: loaded,
              failed: failed,
              fontFamily: loaded ? family : null,
            ),
          ),
        );
      },
    );
  }
}
