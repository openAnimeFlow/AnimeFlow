import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/core/exception/storage_exception.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:url_launcher/url_launcher.dart';

@Dependencies([AnimeInfo, animeInfoArgs])
class InfoAppbar extends ConsumerWidget {
  const InfoAppbar({super.key});

  static const double _controlSize = 44;

  Color _controlColor(ThemeData theme) =>
      theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHigh;

  Future<void> _openInBrowser(String url, AppLocalizations l10n) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationToast.show(l10n.unableOpenLink,
          title: l10n.error, maxWidth: 500);
    }
  }

  Future<void> _copyUrl(
    BuildContext context,
    String url,
    AppLocalizations l10n,
  ) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      NotificationToast.show(l10n.websiteLinkCopied,
          title: l10n.copied, maxWidth: 500);
    }
  }

  Future<void> _downloadCover(
    WidgetRef ref,
    String image,
    String name,
    AppLocalizations l10n,
  ) async {
    try {
      final message =
          await ref.read(animeInfoProvider.notifier).downloadCover(image, name);
      NotificationToast.show(message, title: l10n.tip, maxWidth: 500);
    } on StoragePermissionDeniedException catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show(e.message, title: l10n.tip, maxWidth: 500);
    } catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show(l10n.saveImageFailed(e.toString()),
          title: l10n.tip, maxWidth: 500);
    }
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    MoreMenuAction action,
  ) {
    final args = ref.read(animeInfoArgsProvider);
    final l10n = AppLocalizations.of(context);
    final url = '${CommonApi.bgmTV}/subject/${args.id}';
    switch (action) {
      case MoreMenuAction.openInBrowser:
        _openInBrowser(url, l10n);
        break;
      case MoreMenuAction.downloadCover:
        _downloadCover(ref, args.image, args.name, l10n);
        break;
      case MoreMenuAction.copyUrl:
        _copyUrl(context, url, l10n);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final isPinned =
        settings != null && settings.currentExtent - settings.minExtent < 0.5;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 8,
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: _controlColor(theme),
              foregroundColor: colors.onSurface,
              fixedSize: const Size.square(_controlSize),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const CircleBorder(),
            ),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            iconSize: 23,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _buildInfo(context, ref, isPinned: isPinned)),
          _buildMenu(context, ref),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final backgroundColor = _controlColor(theme);
    return JellyMenu<MoreMenuAction>(
      tooltip: l10n.moreActions,
      triggerColor: backgroundColor,
      menuColor: backgroundColor,
      preferredVerticalDirection: VerticalDirection.down,
      trigger: SizedBox.square(
        dimension: _controlSize,
        child: Icon(Icons.more_vert_rounded, size: 23, color: colors.onSurface),
      ),
      menuBuilder: (context, select) {
        final itemStyle = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: JellyMenu.itemPadding(context),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final action in MoreMenuAction.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextButton(
                      onPressed: () => select(action),
                      style: itemStyle,
                      child: Row(
                        children: [
                          Icon(action.icon, size: 20),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              action.label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      onSelected: (action) => _handleMenuAction(context, ref, action),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    WidgetRef ref, {
    required bool isPinned,
  }) {
    final args = ref.watch(animeInfoArgsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedOpacity(
      opacity: isPinned ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: _controlColor(theme),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: _controlSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 8,
            children: [
              AnimationNetworkImage(
                gaplessResize: true,
                width: _controlSize,
                height: _controlSize,
                fit: BoxFit.cover,
                url: args.image,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        args.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Flexible(flex: 2, child: _buildRating()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating() {
    return Consumer(builder: (context, ref, child) {
      final rating = ref.watch(animeInfoProvider.select(
        (state) => state.value?.rating,
      ));
      if (rating == null || rating.rank <= 0) return const SizedBox.shrink();
      final theme = Theme.of(context);
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          spacing: 5,
          children: [
            RankingView(ranking: rating.rank),
            StarView(score: rating.score, iconSize: 12),
            Text(
              rating.score.toStringAsFixed(1),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// 更多菜单操作枚举
enum MoreMenuAction {
  openInBrowser(Icons.open_in_browser),
  downloadCover(Icons.download),
  copyUrl(Icons.link);

  final IconData icon;

  const MoreMenuAction(this.icon);

  String label(AppLocalizations l10n) => switch (this) {
        MoreMenuAction.openInBrowser => l10n.openInBrowser,
        MoreMenuAction.downloadCover => l10n.downloadCover,
        MoreMenuAction.copyUrl => l10n.copyWebsite,
      };
}
