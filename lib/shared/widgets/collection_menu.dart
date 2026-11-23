import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/collect_type.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';

/// 将 Bangumi API 的收藏类型转换为 [CollectType]。
CollectType? collectTypeFromApiType(int? apiType) {
  if (apiType == null) return null;
  final type = CollectType.fromValue(apiType);
  return type == CollectType.none ? null : type;
}

enum _CollectionMenuVariant { labeled, icon }

class CollectionMenu extends StatefulWidget {
  const CollectionMenu.labeled({
    super.key,
    required this.collectType,
    double layoutScale = 1,
    this.onOpenChanged,
    required this.onCollectTypeChanged,
  })  : _variant = _CollectionMenuVariant.labeled,
        _layoutScale = layoutScale,
        _iconColor = null,
        _iconSize = 18;

  const CollectionMenu.icon({
    super.key,
    required this.collectType,
    Color? iconColor,
    double iconSize = 20,
    this.onOpenChanged,
    required this.onCollectTypeChanged,
  })  : _variant = _CollectionMenuVariant.icon,
        _layoutScale = 1,
        _iconColor = iconColor,
        _iconSize = iconSize;

  final CollectType? collectType;
  final ValueChanged<bool>? onOpenChanged;
  final Future<void> Function(CollectType) onCollectTypeChanged;

  final _CollectionMenuVariant _variant;
  final double _layoutScale;
  final Color? _iconColor;
  final double _iconSize;

  @override
  State<CollectionMenu> createState() => _CollectionMenuState();
}

class _CollectionMenuState extends State<CollectionMenu> {
  late CollectType? _displayType = widget.collectType;
  bool _isUpdating = false;

  @override
  void didUpdateWidget(CollectionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectType != widget.collectType) {
      _displayType = widget.collectType;
    }
  }

  Future<void> _select(CollectType type) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.onCollectTypeChanged(type);
      if (mounted) {
        setState(() => _displayType = type.isCollected ? type : null);
      }
    } catch (_) {
      // The caller handles request failures and displays the error.
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final scale = widget._layoutScale;
    final current = _displayType == CollectType.none ? null : _displayType;
    final label =
        current == null ? l10n.collection : _collectTypeLabel(current, l10n);
    final icon = current == null ? Icons.favorite_border : Icons.favorite;

    return JellyMenu<CollectType>(
      preferredVerticalDirection: VerticalDirection.down,
      enabled: !_isUpdating,
      onOpenChanged: widget.onOpenChanged,
      triggerColor: switch (widget._variant) {
        _CollectionMenuVariant.icon => Colors.transparent,
        _CollectionMenuVariant.labeled =>
          _isUpdating ? colors.primary.withValues(alpha: .6) : colors.primary,
      },
      tooltip: label,
      trigger: switch (widget._variant) {
        _CollectionMenuVariant.icon => SizedBox.square(
            dimension: 40,
            child: Opacity(
              opacity: _isUpdating ? .6 : 1,
              child: Icon(
                icon,
                size: widget._iconSize,
                color: widget._iconColor ?? colors.primaryContainer,
              ),
            ),
          ),
        _CollectionMenuVariant.labeled => ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: 100 * scale, minHeight: 40 * scale),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * scale, vertical: 8 * scale),
              child: Row(
                spacing: 8 * scale,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: widget._iconSize * scale, color: colors.onPrimary),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 12 * scale, color: colors.onPrimary),
                  ),
                ],
              ),
            ),
          ),
      },
      onSelected: _select,
      menuBuilder: (context, select) {
        final types = CollectType.values
            .where(
              (type) => type.isCollected || current != null,
            )
            .toList();
        final itemStyle = TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: JellyMenu.itemPadding(context),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context).textTheme.labelLarge,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final type in types)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextButton(
                      onPressed: type == current ? null : () => select(type),
                      style: itemStyle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_collectTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_collectTypeLabel(type, l10n),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}

IconData _collectTypeIcon(CollectType type) => switch (type) {
      CollectType.watching => Icons.subscriptions_outlined,
      CollectType.planToWatch => Icons.bookmark_outline,
      CollectType.onHold => Icons.pending_actions_outlined,
      CollectType.watched => Icons.task_alt_outlined,
      CollectType.abandoned => Icons.auto_delete_outlined,
      CollectType.none => Icons.bookmark_remove_outlined,
    };

String _collectTypeLabel(CollectType type, AppLocalizations l10n) =>
    switch (type) {
      CollectType.planToWatch => l10n.collectionPlanToWatch,
      CollectType.watched => l10n.collectionWatched,
      CollectType.watching => l10n.collectionWatching,
      CollectType.onHold => l10n.collectionOnHold,
      CollectType.abandoned => l10n.collectionAbandoned,
      CollectType.none => l10n.cancelCollection,
    };
