import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:material_ui/material_ui.dart';

class WallpaperFilterResult {
  const WallpaperFilterResult({required this.keyword, required this.sort});

  final String keyword;
  final SortType sort;
}

/// 壁纸墙排序方式的本地化文案，弹窗与已生效条件标签共用。
String wallpaperSortLabel(AppLocalizations l10n, SortType sort) =>
    switch (sort) {
      SortType.trends => l10n.sortTrends,
      SortType.collects => l10n.collection,
      SortType.rank => l10n.sortRank,
      SortType.date => l10n.sortDate,
      SortType.title => sort.name,
    };

/// 壁纸墙筛选弹窗：排序方式与关键词，确认后由调用方重新拉取第一页。
class WallpaperFilterDialog extends StatefulWidget {
  const WallpaperFilterDialog({
    super.key,
    required this.initialKeyword,
    required this.initialSort,
  });

  final String initialKeyword;
  final SortType initialSort;

  @override
  State<WallpaperFilterDialog> createState() => _WallpaperFilterDialogState();
}

class _WallpaperFilterDialogState extends State<WallpaperFilterDialog> {
  /// 壁纸墙支持的排序方式，顺序与入口按钮一致。
  static const _sorts = [
    SortType.trends,
    SortType.collects,
    SortType.rank,
    SortType.date,
  ];

  late final TextEditingController _controller;
  late SortType _sort;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    _sort = widget.initialSort;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      WallpaperFilterResult(keyword: _controller.text.trim(), sort: _sort),
    );
  }

  void _reset() {
    _controller.clear();
    setState(() => _sort = SortType.trends);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.filterWallpapers),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.wallpaperKeywordHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: l10n.clearSearch,
                    onPressed: _controller.clear,
                    icon: const Icon(Icons.clear),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    flex: 2,
                    child: DropDownMenu<SortType>(
                      items: _sorts,
                      selectedItem: _sort,
                      tooltip: l10n.wallpaperSortLabel,
                      offset: const Offset(0, 48),
                      buttonBorderRadius: BorderRadius.circular(8),
                      buttonBuilder: (context, selected) => Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                wallpaperSortLabel(l10n, selected ?? _sort),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      itemBuilder: (context, sort, isSelected) => Row(
                        children: [
                          Expanded(child: Text(wallpaperSortLabel(l10n, sort))),
                          if (isSelected) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.check,
                                size: 18, color: colorScheme.primary),
                          ],
                        ],
                      ),
                      onSelected: (sort) => setState(() => _sort = sort),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: Text(l10n.resetFilters),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
