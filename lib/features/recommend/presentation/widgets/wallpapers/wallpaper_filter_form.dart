import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:material_ui/material_ui.dart';

class WallpaperFilterResult {
  const WallpaperFilterResult({required this.keyword, required this.sort});

  final String keyword;
  final SortType sort;
}

/// 壁纸墙排序方式的本地化文案，筛选表单与已生效条件标签共用。
String wallpaperSortLabel(AppLocalizations l10n, SortType sort) =>
    switch (sort) {
      SortType.trends => l10n.sortTrends,
      SortType.collects => l10n.collection,
      SortType.rank => l10n.sortRank,
      SortType.date => l10n.sortDate,
      SortType.title => sort.name,
    };

class WallpaperFilterForm extends StatefulWidget {
  const WallpaperFilterForm({
    super.key,
    required this.initialKeyword,
    required this.initialSort,
    required this.onKeyboardAnchorHeightChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final String initialKeyword;
  final SortType initialSort;
  final ValueChanged<double> onKeyboardAnchorHeightChanged;
  final ValueChanged<WallpaperFilterResult> onSubmit;
  final VoidCallback onCancel;

  @override
  State<WallpaperFilterForm> createState() => _WallpaperFilterFormState();
}

class _WallpaperFilterFormState extends State<WallpaperFilterForm> {
  static const _sorts = [
    SortType.trends,
    SortType.collects,
    SortType.rank,
    SortType.date,
  ];

  late final TextEditingController _controller;
  late SortType _sort;
  final _keywordSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    _sort = widget.initialSort;
    _reportKeyboardAnchorHeight();
  }

  void _reportKeyboardAnchorHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _keywordSectionKey.currentContext?.size?.height;
      if (height != null) widget.onKeyboardAnchorHeightChanged(height);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSubmit(
      WallpaperFilterResult(keyword: _controller.text.trim(), sort: _sort),
    );
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    widget.onCancel();
  }

  void _reset() {
    _controller.clear();
    setState(() => _sort = SortType.trends);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 360,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _reportKeyboardAnchorHeight();
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: Padding(
                  key: _keywordSectionKey,
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.filterWallpapers, style: textTheme.titleMedium),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.wallpaperSortLabel, style: textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final sort in _sorts)
                  ChoiceChip(
                    label: Text(wallpaperSortLabel(l10n, sort)),
                    selected: sort == _sort,
                    onSelected: (_) => setState(() => _sort = sort),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(l10n.resetFilters),
                ),
                TextButton(
                  onPressed: _cancel,
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
