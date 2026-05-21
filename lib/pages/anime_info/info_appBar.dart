import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/drop_down_menu.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/utils/exceptions/storage_exception.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoAppbar extends StatelessWidget {
  final bool isPinned;
  final SubjectBasicData subjectBasicData;

  const InfoAppbar({
    super.key,
    required this.isPinned,
    required this.subjectBasicData,
  });

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationToast.show('错误', '无法打开链接', maxWidth: 500);
    }
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      NotificationToast.show('已复制', '网站链接已复制到剪贴板', maxWidth: 500);
    }
  }

  Future<void> _downloadCover() async {
    try {
      final message = await Request.downloadImage(
        subjectBasicData.image,
        subjectBasicData.name,
      );
      NotificationToast.show('提示', message, maxWidth: 500);
    } on StoragePermissionDeniedException catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show('提示', e.message, maxWidth: 500);
    } catch (e) {
      LiggLogger().e('保存图片失败:$e');
      NotificationToast.show('提示', '保存图片失败:$e', maxWidth: 500);
    }
  }

  void _handleMenuAction(BuildContext context, MoreMenuAction action) {
    final url = '${CommonApi.bgmTV}/subject/${subjectBasicData.id}';
    switch (action) {
      case MoreMenuAction.openInBrowser:
        _openInBrowser(url);
        break;
      case MoreMenuAction.downloadCover:
        _downloadCover();
        break;
      case MoreMenuAction.copyUrl:
        _copyUrl(context, url);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          iconSize: 25,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: Get.back,
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final infoAsync = ref.watch(animeInfoProvider(subjectBasicData.id));
              return infoAsync.when(
                data: (data) => _buildInfo(data),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ),
        _buildMenu(context),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    return DropDownMenu<MoreMenuAction>(
      tooltip: '更多操作',
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
            Text(item.label),
          ],
        );
      },
      onSelected: (action) => _handleMenuAction(context, action),
    );
  }

  Widget _buildInfo(SubjectsInfoItem subjectsItem) {
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
              url: subjectBasicData.image,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subjectBasicData.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (subjectsItem.rating.rank > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RankingView(ranking: subjectsItem.rating.rank),
                        StarView(score: subjectsItem.rating.score),
                        const SizedBox(width: 5),
                        Text(
                          subjectsItem.rating.score.toStringAsFixed(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
  openInBrowser('浏览器查看', Icons.open_in_browser),
  downloadCover('下载封面', Icons.download),
  copyUrl('复制网站', Icons.link);

  final String label;
  final IconData icon;

  const MoreMenuAction(this.label, this.icon);
}
