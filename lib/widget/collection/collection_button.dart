import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/collect_type.dart';
import 'package:anime_flow/models/item/bangumi/subjects_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionButton extends StatefulWidget {
  final int subjectId;
  final SubjectsItem subject;

  const CollectionButton(
      {super.key, required this.subjectId, required this.subject});

  @override
  State<CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<CollectionButton> {
  late UserInfoStore userInfoStore;

  CollectType? _getCurrentCollectType() {
    if (widget.subject.interest == null) return null;
    final apiType = widget.subject.interest!.type;
    switch (apiType) {
      case 1: // 想看 -> CollectType.planToWatch (2)
        return CollectType.planToWatch;
      case 2: // 看过 -> CollectType.watched (4)
        return CollectType.watched;
      case 3: // 在看 -> CollectType.watching (1)
        return CollectType.watching;
      case 4: // 搁置 -> CollectType.onHold (3)
        return CollectType.onHold;
      case 5: // 抛弃 -> CollectType.abandoned (5)
        return CollectType.abandoned;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    userInfoStore = Get.find<UserInfoStore>();
  }

  @override
  Widget build(BuildContext context) {
    final currentCollectType = _getCurrentCollectType();

    return Obx(() => userInfoStore.userInfo.value == null
        ? OutlinedButton(
            onPressed: () => Get.offAllNamed(
              RouteName.main,
              arguments: 2,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              '登录后收藏',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : PopupMenuButton<CollectType>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentCollectType != null
                        ? _getCollectTypeIcon(currentCollectType)
                        : Icons.play_circle_outline,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentCollectType?.label ?? '收藏',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) {
              return CollectType.values
                  .where((type) => type != CollectType.none)
                  .map((type) {
                final isCurrentType = type == currentCollectType;
                return PopupMenuItem<CollectType>(
                  value: type,
                  enabled: !isCurrentType,
                  child: Row(
                    children: [
                      Icon(
                        _getCollectTypeIcon(type),
                        size: 20,
                        color: isCurrentType
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: TextStyle(
                          color: isCurrentType
                              ? Theme.of(context).disabledColor
                              : null,
                        ),
                      ),
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
                // 更新本地状态
                if (widget.subject.interest != null) {
                  setState(() {
                    widget.subject.interest!.type = apiType;
                  });
                }
                if (context.mounted) {
                  Get.snackbar('收藏更新', '已${type.label}', maxWidth: 500);
                }
              } catch (e) {
                if (context.mounted) {
                  Get.snackbar('操作失败', '$e', maxWidth: 500);
                }
              }
            },
          ));
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
        return Icons.subscriptions_outlined;
      case CollectType.planToWatch:
        return Icons.bookmark_outline;
      case CollectType.onHold:
        return Icons.pending_actions_outlined;
      case CollectType.watched:
        return Icons.task_alt_outlined;
      case CollectType.abandoned:
        return Icons.auto_delete_outlined;
      case CollectType.none:
        return Icons.circle_outlined;
    }
  }
}
