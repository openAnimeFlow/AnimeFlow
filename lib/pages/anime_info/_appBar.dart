part of 'index.dart';

class _Appbar extends StatelessWidget {
  final bool isPinned;
  final SubjectBasicData subjectBasicData;
  final SubjectsInfoItem? subjectsItem;

  const _Appbar({
    required this.subjectsItem,
    required this.isPinned,
    required this.subjectBasicData,
  });

  void _handleMenuAction(BuildContext context, MoreMenuAction action) {
    final subjectId = subjectsItem?.id ?? subjectBasicData.id;
    final url = '${CommonApi.bgmTV}/subject/$subjectId';

    switch (action) {
      case MoreMenuAction.openInBrowser:
        _openInBrowser(url);
        break;
      case MoreMenuAction.downloadCover:
        Utils.downloadImage(subjectBasicData.image, subjectBasicData.name);
        break;
      case MoreMenuAction.copyUrl:
        _copyUrl(context, url);
        break;
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('错误', '无法打开链接', maxWidth: 500);
    }
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      Get.snackbar('已复制', '网站链接已复制到剪贴板', maxWidth: 500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: const EdgeInsets.all(0),
          iconSize: 25,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Get.back();
          },
        ),
        if (subjectsItem != null)
          Expanded(child: _buildInfo)
        else
          const Spacer(),
        Builder(
          builder: (context) {
            return DropDownMenu<MoreMenuAction>(
              items: MoreMenuAction.values,
              offset: const Offset(0, 40),
              disableSelected: false,
              buttonBuilder: (context, selectedItem) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
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
              onSelected: (MoreMenuAction action) {
                _handleMenuAction(context, action);
              },
            );
          },
        )
      ],
    );
  }

  Widget get _buildInfo {
    final data = subjectsItem!;
    return AnimatedOpacity(
      opacity: isPinned ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        children: [
          AnimationNetworkImage(
              borderRadius: BorderRadius.circular(5),
              width: 26,
              height: 36,
              fit: BoxFit.cover,
              url: subjectBasicData.image),
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
                if(data.rating.rank > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RankingView(ranking: data.rating.rank),
                    StarView(score: data.rating.score),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        data.rating.score.toStringAsFixed(1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
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
