import 'package:flutter/material.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class CollectionSearchDialog extends StatefulWidget {
  final String initialKeyword;

  const CollectionSearchDialog({super.key, required this.initialKeyword});

  @override
  State<CollectionSearchDialog> createState() => _CollectionSearchDialogState();
}

class _CollectionSearchDialogState extends State<CollectionSearchDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.searchCollection),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.collectionKeywordHint,
          prefixIcon: const Icon(Icons.search),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.search),
        ),
      ],
    );
  }
}
