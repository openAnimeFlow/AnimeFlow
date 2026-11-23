import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/collection_sort.dart';
import 'package:material_ui/material_ui.dart';

class CollectionFilterResult {
  final String keyword;
  final CollectionSort sort;

  const CollectionFilterResult({required this.keyword, required this.sort});
}

class CollectionFilterForm extends StatefulWidget {
  final String initialKeyword;
  final CollectionSort initialSort;
  final ValueChanged<CollectionFilterResult> onSubmit;
  final VoidCallback onCancel;

  const CollectionFilterForm({
    super.key,
    required this.initialKeyword,
    required this.initialSort,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<CollectionFilterForm> createState() => _CollectionFilterFormState();
}

class _CollectionFilterFormState extends State<CollectionFilterForm> {
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
    final keyword = _controller.text.trim();
    FocusScope.of(context).unfocus();
    if (keyword == widget.initialKeyword.trim() &&
        _sort == widget.initialSort) {
      widget.onCancel();
      return;
    }
    widget.onSubmit(
      CollectionFilterResult(keyword: keyword, sort: _sort),
    );
  }

  void _reset() {
    _controller.clear();
    setState(() => _sort = CollectionSort.defaultSort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: 360,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (constraints.maxHeight - keyboardHeight)
                .clamp(0.0, constraints.maxHeight),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.filterCollection, style: textTheme.titleMedium),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                Text(l10n.collectionSortLabel, style: textTheme.labelLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final sort in CollectionSort.values)
                      ChoiceChip(
                        label: Text(switch (sort) {
                          CollectionSort.defaultSort => l10n.defaultSort,
                          CollectionSort.watch => l10n.collectionSortWatch,
                        }),
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
                      child: Text(l10n.resetCollectionFilters),
                    ),
                    TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        widget.onCancel();
                      },
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
        ),
      ),
    );
  }
}
