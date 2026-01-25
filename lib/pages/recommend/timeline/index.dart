import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/timeline_item.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage>
    with AutomaticKeepAliveClientMixin {
  List<TimelineItem> timelineData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _getTimelineData() async {
    try {
      setState(() {
        isLoading = true;
      });
      final data = await BgmRequest.timelineService(20);
      if (mounted) {
        setState(() {
          timelineData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  bool get wantKeepAlive => true;

  // 检查条目是否有可渲染的内容
  bool _hasValidContent(TimelineItem item) {
    try {
      final progress = item.memo.progress;
      return progress.single.episode.id > 0 && progress.single.subject.id > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(child: Text('施工中...'));
  }
//   if (isLoading && timelineData.isEmpty) {
//     return const Center(child: CircularProgressIndicator());
//   }
//
//   // 过滤出有可渲染内容的条目
//   final validItems = timelineData.where(_hasValidContent).toList();
//
//   if (validItems.isEmpty) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text('暂无数据'),
//           TextButton(
//             onPressed: _getTimelineData,
//             child: const Text('刷新'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   return ListView.builder(
//     padding: const EdgeInsets.all(16),
//     itemCount: validItems.length,
//     itemBuilder: (context, index) {
//       final item = validItems[index];
//       return _buildTimelineItem(item);
//     },
//   );
// }

// Widget _buildTimelineItem(TimelineItem item) {
//   return Card(
//     margin: const EdgeInsets.only(bottom: 16),
//     child: Padding(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 用户信息
//           Row(
//             children: [
//               AnimationNetworkImage(
//                   url: item.user.avatar.small,
//                   width: 40,
//                   height: 40,
//                   borderRadius: BorderRadius.circular(30)),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item.user.nickname.isNotEmpty
//                           ? item.user.nickname
//                           : item.user.username,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                     Text(
//                       _formatTime(item.createdAt),
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // 内容区域
//           _buildContent(item),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildContent(TimelineItem item) {
//   // 根据类型显示不同的内容
//   // type: 2, cat: 4 表示观看进度
//   if (item.type == 2 && item.cat == 4) {
//     return _buildProgressContent(item);
//   }
//   // 其他类型可以在这里扩展
//   return const SizedBox.shrink();
// }
//
// Widget _buildProgressContent(TimelineItem item) {
//   final single = item.memo.progress.single;
//   final episode = single.episode;
//   final subject = single.subject;
//
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // 封面图
//       ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: AnimationNetworkImage(
//           url: subject.images.medium,
//           width: 80,
//           height: 112,
//           fit: BoxFit.cover,
//         ),
//       ),
//       const SizedBox(width: 12),
//       // 内容信息
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               subject.nameCN.isNotEmpty ? subject.nameCN : subject.name,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '看到了第 ${episode.sort} 话',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//               ),
//             ),
//             if (episode.nameCN.isNotEmpty || episode.name.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(
//                   episode.nameCN.isNotEmpty ? episode.nameCN : episode.name,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     ],
//   );
// }
}
