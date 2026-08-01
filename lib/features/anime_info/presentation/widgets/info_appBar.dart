import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/exception/storage_exception.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoAppbar extends ConsumerWidget {
  final bool isPinned;

  const InfoAppbar({
    super.key,
    required this.isPinned,
  });

  Future<void> _openInBrowser(String url, AppLocalizations l10n) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationToast.show(l10n.error, l10n.unableOpenLink, maxWidth: 500);
    }
  }

  Future<void> _copyUrl(
    BuildContext context,
    String url,
    AppLocalizations l10n,
  ) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      NotificationToast.show(l10n.copied, l10n.websiteLinkCopied,
          maxWidth: 500);
    }
  }

  Future<void> _downloadCover(
    String image,
    String name,
    AppLocalizations l10n,
  ) async {
    try {
      final message = await Api.downloadImage(image, name);
      NotificationToast.show(l10n.tip, message, maxWidth: 500);
    } on StoragePermissionDeniedException catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show(l10n.tip, e.message, maxWidth: 500);
    } catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show(l10n.tip, l10n.saveImageFailed(e.toString()),
          maxWidth: 500);
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
        _downloadCover(args.image, args.name, l10n);
        break;
      case MoreMenuAction.copyUrl:
        _copyUrl(context, url, l10n);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          iconSize: 25,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        Expanded(
          child: _buildInfo(ref),
        ),
        _buildMenu(context, ref),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DropDownMenu<MoreMenuAction>(
      tooltip: l10n.moreActions,
      items: MoreMenuAction.values,
      offset: const Offset(0, 40),
      disableSelected: false,
      buttonBuilder: (context, selectedItem) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.share_outlined,
            size: 25,
          ),
        );
      },
      itemBuilder: (context, item, isSelected) {
        return Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(item.label(l10n)),
          ],
        );
      },
      onSelected: (action) => _handleMenuAction(context, ref, action),
    );
  }

  Widget _buildInfo(WidgetRef ref) {
    final args = ref.watch(animeInfoArgsProvider);
    return AnimatedOpacity(
      opacity: isPinned ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isPinned,
        child: Row(
          children: [
            AnimationNetworkImage(
              borderRadius: BorderRadius.circular(5),
              width: 26,
              height: 36,
              fit: BoxFit.cover,
              url: args.image,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    args.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Consumer(builder: (context, ref, child) {
                    final infoAsync = ref.watch(animeInfoProvider);
                    return infoAsync.when(
                        data: (data) => data.rating.rank > 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RankingView(ranking: data.rating.rank),
                                  StarView(score: data.rating.score),
                                  const SizedBox(width: 5),
                                  Text(
                                    data.rating.score.toStringAsFixed(1),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink());
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
