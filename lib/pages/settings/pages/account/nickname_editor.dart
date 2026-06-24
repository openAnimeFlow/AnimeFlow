import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';

class NicknameEditorView extends StatefulWidget {
  const NicknameEditorView({
    super.key,
    required this.nickname,
    required this.displayText,
    required this.onConfirm,
  });

  final String nickname;
  final String displayText;
  final Future<void> Function(String nickname) onConfirm;

  @override
  State<NicknameEditorView> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditorView> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nickname);
  }

  @override
  void didUpdateWidget(covariant NicknameEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.nickname != widget.nickname) {
      _controller.text = widget.nickname;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.nickname;
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return;

    final newNickname = _controller.text.trim();
    if (newNickname.isEmpty) {
      NotificationToast.show('提示', '昵称不能为空');
      return;
    }

    if (newNickname == widget.nickname) {
      setState(() => _isEditing = false);
      _focusNode.unfocus();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(newNickname);
      if (!mounted) return;
      setState(() => _isEditing = false);
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_isSubmitting,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirm(),
                )
              : Text(
                  widget.displayText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (_isEditing)
        IconButton(
            onPressed: () => setState(() => _isEditing = false),
            icon: const Icon(Icons.close_rounded)),
        IconButton(
          onPressed: _isSubmitting
              ? null
              : _isEditing
                  ? _confirm
                  : _startEditing,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isEditing ? Icons.check : Icons.edit),
        ),
      ],
    );
  }
}
