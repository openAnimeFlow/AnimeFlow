import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/app/router/model/wallpaper_detail_args.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

class WallpaperDetailPage extends StatefulWidget {
  const WallpaperDetailPage(
      {super.key, required this.args, this.onClose, this.onOpenRelated});

  final WallpaperDetailArgs args;
  final VoidCallback? onClose;
  final ValueChanged<WallpaperDetailArgs>? onOpenRelated;

  @override
  State<WallpaperDetailPage> createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends State<WallpaperDetailPage> {
  final _sizes = <String, Size>{};
  final _thumbnails = ScrollController();
  double _thumbnailItemExtent = 104;
  double _thumbnailSpacing = 8;
  int? _selectionTarget;
  late final List<String> _images;
  late final PageController _pages;
  late int _index;
  bool _downloading = false;
  bool _sharing = false;

  SubjectWallpaper get _subject => widget.args.subject;

  String get _url => _images[_index];

  bool get _isBackdrop => _subject.backdrops.contains(_url);

  @override
  void initState() {
    super.initState();
    _images = {
      if (widget.args.initialUrl.trim().isNotEmpty) widget.args.initialUrl,
      ..._subject.coverImages,
    }.toList(growable: false);
    _index = 0;
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    _thumbnails.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    NotificationToast.show(message);
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
    });
    // 跨多页的点击动画会经过中间页，不让中间页拉动缩略图列表。
    if (_selectionTarget == null) _scrollToThumbnail();
  }

  void _scrollToThumbnail({bool animate = true}) {
    if (!mounted || !_thumbnails.hasClients) return;
    final position = _thumbnails.position;
    if (!position.hasContentDimensions) return;
    final start = _index * _thumbnailItemExtent;
    final end = start + _thumbnailItemExtent - _thumbnailSpacing;
    final visibleStart = position.pixels;
    final visibleEnd = visibleStart + position.viewportDimension;
    if (start >= visibleStart - 0.5 && end <= visibleEnd + 0.5) return;
    // 只补足被遮挡的部分，已完整可见时保留用户手动滚动的位置。
    final offset =
        (start < visibleStart ? start : end - position.viewportDimension)
            .clamp(0.0, position.maxScrollExtent);
    if ((offset - position.pixels).abs() < 0.5) return;
    if (animate) {
      unawaited(_thumbnails.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ));
    } else {
      _thumbnails.jumpTo(offset);
    }
  }

  Future<void> _select(int index) async {
    if (index < 0 || index >= _images.length || index == _index) return;
    _selectionTarget = index;
    try {
      await _pages.animateToPage(index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    } finally {
      if (mounted && _selectionTarget == index) {
        _selectionTarget = null;
        _scrollToThumbnail();
      }
    }
  }

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    final url = _url;
    final filename = 'wallpaper_${_subject.subjectId}_${_index + 1}';
    setState(() => _downloading = true);
    try {
      _message(await Api.downloadImage(url, filename));
    } catch (error) {
      _message(l10n.saveImageFailed(error.toString()));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final l10n = AppLocalizations.of(context);
    final text = '${_subject.displayName}\n$_url';
    setState(() => _sharing = true);
    try {
      if (SystemUtil.isDesktop) {
        await Clipboard.setData(ClipboardData(text: text));
        _message(l10n.copied);
      } else {
        final box = buttonContext.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(ShareParams(
          text: text,
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ));
      }
    } catch (_) {
      _message(l10n.wallpaperActionFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _reportSize(String url, Size size) {
    if (!mounted || _sizes[url] == size) return;
    setState(() => _sizes[url] = size);
  }

  void _preview() => ImagePreviewRoute.fromArgs(ImageViewerRouteArgs(
        imageUrls: _images,
        initialIndex: _index,
      )).push(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (_images.isEmpty) {
      return Scaffold(
          appBar: AppBar(
              leading: widget.onClose == null
                  ? null
                  : CloseButton(onPressed: widget.onClose),
              title: Text(l10n.wallpapers)),
          body: Center(child: Text(l10n.noData)));
    }
    return Scaffold(
      appBar: AppBar(
        leading: widget.onClose == null
            ? null
            : CloseButton(onPressed: widget.onClose),
        title: Text(_subject.nameCn.isEmpty ? _subject.name : _subject.nameCn),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1800),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _gallery(l10n),
                    const SizedBox(height: 12),
                    _thumbnailStrip(colors),
                    const SizedBox(height: 24),
                    _information(l10n, colors),
                    const SizedBox(height: 24),
                    Divider(color: colors.outlineVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(l10n.wallpaperImageSize,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      _InfoPill(
                        label: _sizes[_url] == null
                            ? l10n.loading
                            : '${_sizes[_url]!.width.toInt()} × ${_sizes[_url]!.height.toInt()}',
                        highlighted: true,
                      ),
                      _InfoPill(
                          label: _isBackdrop
                              ? l10n.wallpaperBackdrop
                              : l10n.wallpaperPoster),
                      _InfoPill(label: l10n.wallpaperImageCount(_images.length)),
                    ]),
                    const SizedBox(height: 22),
                    _actions(l10n),
                    if (_related.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Divider(
                          color: colors.outlineVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(l10n.wallpaperMore,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      _relatedWallpapers(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gallery(AppLocalizations l10n) => AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                controller: _pages,
                itemCount: _images.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: _preview,
                  child: AnimationNetworkImage(
                    url: _images[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholderWidth: double.infinity,
                    placeholderHeight: double.infinity,
                    onImageSize: (size) => _reportSize(_images[index], size),
                  ),
                ),
              ),
              if (_images.length > 1) ...[
                Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _GalleryButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: l10n.wallpaperPrevious,
                        onPressed:
                            _index > 0 ? () => _select(_index - 1) : null,
                      ),
                    )),
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _GalleryButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: l10n.wallpaperNext,
                        onPressed: _index + 1 < _images.length
                            ? () => _select(_index + 1)
                            : null,
                      ),
                    )),
              ],
              Positioned(
                  bottom: 12,
                  right: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        child: Text('${_index + 1} / ${_images.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12))),
                  )),
            ]),
          ),
        ),
      );

  Widget _thumbnailStrip(ColorScheme colors) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = math.min(
            width,
            width < 600
                ? 96.0
                : width < 1024
                    ? 136.0
                    : 176.0);
        final spacing = width < 600 ? 3.0 : 6.0;
        _thumbnailSpacing = spacing;
        // 边框 2 + 内边距 3，两侧共占 10；图片区域保持 16:9。
        final imageWidth = math.max(0.0, tileWidth - 10);
        final imageHeight = imageWidth * 9 / 16;
        final itemExtent = tileWidth + spacing;
        if (_thumbnailItemExtent != itemExtent) {
          _thumbnailItemExtent = itemExtent;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToThumbnail(animate: false);
          });
        }
        return SizedBox(
          height: imageHeight + 10,
          child: ListView.builder(
            controller: _thumbnails,
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemExtent: itemExtent,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(right: spacing),
              child: Semantics(
                button: true,
                selected: _index == index,
                label:
                    AppLocalizations.of(context).wallpaperThumbnail(index + 1),
                child: InkWell(
                  onTap: () => _select(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            width: 2,
                            color: _index == index
                                ? colors.primary
                                : Colors.transparent)),
                    child: AnimationNetworkImage(
                      url: _images[index],
                      fit: BoxFit.cover,
                      width: imageWidth,
                      height: imageHeight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      });

  Widget _information(AppLocalizations l10n, ColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_subject.displayName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Bangumi #${_subject.subjectId}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
                FilledButton(
                    onPressed: () => AnimeInfoRoute(
                            id: _subject.subjectId,
                            name: _subject.displayName,
                            image: _url)
                        .push(context),
                    child: Text(l10n.wallpaperViewAnime)),
              ]),
          if (_subject.name != _subject.displayName) ...[
            const SizedBox(height: 10),
            Text(_subject.name,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ],
      );

  Widget _actions(AppLocalizations l10n) =>
      LayoutBuilder(builder: (context, constraints) {
        final download = FilledButton.icon(
          onPressed: _downloading ? null : _download,
          icon: _downloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.file_download_outlined),
          label: Text(_downloading ? l10n.loading : l10n.wallpaperDownload),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
        );
        final share = Builder(
            builder: (buttonContext) => FilledButton.tonalIcon(
                  onPressed: _sharing ? null : () => _share(buttonContext),
                  icon: Icon(SystemUtil.isDesktop
                      ? Icons.link_rounded
                      : Icons.ios_share_rounded),
                  label: Text(SystemUtil.isDesktop
                      ? l10n.wallpaperCopyLink
                      : l10n.wallpaperShare),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                ));
        if (constraints.maxWidth < 450) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                download,
                const SizedBox(height: 10),
                share,
              ]);
        }
        return Row(children: [
          Expanded(flex: 2, child: download),
          const SizedBox(width: 12),
          Expanded(child: share),
        ]);
      });

  List<SubjectWallpaper> get _related {
    final seen = <int>{_subject.subjectId};
    return widget.args.related
        .where((subject) =>
            subject.coverImages.isNotEmpty && seen.add(subject.subjectId))
        .take(6)
        .toList();
  }

  Widget _relatedWallpapers() => LayoutBuilder(builder: (context, constraints) {
        final subjects = _related;
        final width =
            math.max(130.0, math.min(220.0, (constraints.maxWidth - 24) / 3));
        return SizedBox(
          height: width * 9 / 16 + 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final url = subject.coverImages.first;
              return SizedBox(
                  width: width,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final args = WallpaperDetailArgs(
                        subject: subject,
                        initialUrl: url,
                        related: [_subject, ...widget.args.related],
                      );
                      if (widget.onOpenRelated != null) {
                        widget.onOpenRelated!(args);
                      } else {
                        WallpaperDetailRoute($extra: args).push(context);
                      }
                    },
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimationNetworkImage(
                              url: url,
                              width: width,
                              height: width * 9 / 16,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12)),
                          const SizedBox(height: 8),
                          Text(subject.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  ));
            },
          ),
        );
      });
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton(
      {required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.38),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
        ),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
          color: highlighted ? colors.primary : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: highlighted ? colors.onPrimary : colors.onSurfaceVariant)),
    );
  }
}
