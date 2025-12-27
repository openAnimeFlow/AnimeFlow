import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/collect_type.dart';
import 'package:flutter/material.dart';

class CollectionButton extends StatefulWidget {
  final int subjectId;

  const CollectionButton({super.key, required this.subjectId});

  @override
  State<CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<CollectionButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CollectType>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.play_circle_outline,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              "收藏",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return CollectType.values
            .where((type) => type != CollectType.none)
            .map((type) {
          return PopupMenuItem<CollectType>(
            value: type,
            child: Row(
              children: [
                Icon(
                  _getCollectTypeIcon(type),
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(type.label),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (CollectType type) async {
        try {
          // CollectType 的 value：1=在看, 2=想看, 3=搁置, 4=看过, 5=抛弃
          final apiType = _convertToApiType(type.value);
          await UserRequest.updateCollectionService(
            widget.subjectId,
            type: apiType,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已${type.label}'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('操作失败: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  /// 将 CollectType 的 value 转换为 API 的 type
  /// API 映射：1=想看, 2=看过, 3=在看, 4=搁置, 5=抛弃
  /// CollectType 映射：1=在看, 2=想看, 3=搁置, 4=看过, 5=抛弃
  int _convertToApiType(int collectTypeValue) {
    switch (collectTypeValue) {
      case 1: // 在看 -> 3
        return 3;
      case 2: // 想看 -> 1
        return 1;
      case 3: // 搁置 -> 4
        return 4;
      case 4: // 看过 -> 2
        return 2;
      case 5: // 抛弃 -> 5
        return 5;
      default:
        return 1;
    }
  }

  /// 获取收藏类型对应的图标
  IconData _getCollectTypeIcon(CollectType type) {
    switch (type) {
      case CollectType.watching:
        return Icons.play_circle_outline;
      case CollectType.planToWatch:
        return Icons.bookmark_outline;
      case CollectType.onHold:
        return Icons.pause_circle_outline;
      case CollectType.watched:
        return Icons.check_circle_outline;
      case CollectType.abandoned:
        return Icons.cancel_outlined;
      case CollectType.none:
        return Icons.circle_outlined;
    }
  }
}
