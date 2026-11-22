import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/collection_sort.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';

class CollectionFilterResult {
  final String keyword;
  final CollectionSort sort;

  const CollectionFilterResult({required this.keyword, required this.sort});
}

class CollectionFilterDialog extends StatefulWidget {
  final String initialKeyword;
  final CollectionSort initialSort;

  const CollectionFilterDialog({
    super.key,
    required this.initialKeyword,
    required this.initialSort,
  });

  @override
  State<CollectionFilterDialog> createState() => _CollectionFilterDialogState();
}

class _CollectionFilterDialogState extends State<CollectionFilterDialog> {
  late final TextEditingController _controller;
  late CollectionSort _sort;

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
      CollectionFilterResult(keyword: _controller.text.trim(), sort: _sort),
    );
  }

  void _reset() {
    _controller.clear();
    setState(() => _sort = CollectionSort.defaultSort);
  }

  Widget _buildSortMenu(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    String sortLabel(CollectionSort sort) => switch (sort) {
          CollectionSort.defaultSort => l10n.defaultSort,
          CollectionSort.watch => l10n.collectionSortWatch,
        };

    return JellyMenu<CollectionSort>(
      tooltip: l10n.collectionSortLabel,
      triggerColor: Colors.transparent,
      preferredVerticalDirection: VerticalDirection.down,
      trigger: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                sortLabel(_sort),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      menuBuilder: (context, select) {
        final style = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final sort in CollectionSort.values)
                  TextButton(
                    style: style,
                    onPressed: sort == _sort ? null : () => select(sort),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sortLabel(sort),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sort == _sort) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.check,
                              size: 18, color: colorScheme.primary),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      onSelected: (sort) => setState(() => _sort = sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.filterCollection),
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
                  hintText: l10n.collectionKeywordHint,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('排序'),
                  Flexible(child: _buildSortMenu(context, l10n)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: Text(l10n.resetCollectionFilters),
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
