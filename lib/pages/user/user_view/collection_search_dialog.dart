import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('搜索收藏'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: '输入收藏关键词',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('搜索'),
        ),
      ],
    );
  }
}
