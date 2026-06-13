import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/models/enums/collect_type.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bangumi API type → [CollectType]（API：1=想看, 2=看过, 3=在看, 4=搁置, 5=抛弃）
CollectType? collectTypeFromApiType(int? apiType) {
  if (apiType == null) return null;
  switch (apiType) {
    case 1:
      return CollectType.planToWatch;
    case 2:
      return CollectType.watched;
    case 3:
      return CollectType.watching;
    case 4:
      return CollectType.onHold;
    case 5:
      return CollectType.abandoned;
    default:
      return null;
  }
}

class CollectionButton extends StatefulWidget {
  final CollectType? collectType;

  final Future<void> Function(CollectType type)? onCollectTypeChanged;

  const CollectionButton({
    super.key,
    this.collectType,
    this.onCollectTypeChanged,
  });

  @override
  State<CollectionButton> createState() => _CollectionButtonState();
}

class _CollectionButtonState extends State<CollectionButton> {
  late CollectType? _displayType;

  @override
  void initState() {
    super.initState();
    _displayType = widget.collectType;
  }

  @override
  void didUpdateWidget(CollectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectType != widget.collectType) {
      _displayType = widget.collectType;
    }
  }

  Future<void> _onCollectTypeSelected(CollectType type) async {
    await widget.onCollectTypeChanged?.call(type);
    if (!mounted) return;
    setState(() => _displayType = type);
  }

  @override
  Widget build(BuildContext context) {
    final currentCollectType = _displayType;

    return Consumer(
      builder: (context, ref, _) {
        final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
        return !isLoggedIn
            ? OutlinedButton(
                onPressed: () => const MainRoute(tab: 2).go(context),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                onSelected: _onCollectTypeSelected,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
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
              );
      },
    );
  }

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
