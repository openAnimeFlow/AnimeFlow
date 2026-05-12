import 'package:flutter/material.dart';

/// 弹幕输入框
class DanmakuTextField extends StatefulWidget {
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool leftIcon;
  final bool rightIcon;

  /// 输入框聚焦状态变化（`true` 获得焦点，`false` 失去焦点）
  final ValueChanged<bool>? onFocusChange;

  /// 点击发送或键盘「发送」时回调（
  final ValueChanged<String>? onSend;

  const DanmakuTextField({
    super.key,
    this.iconColor,
    this.textColor,
    this.leftIcon = true,
    this.rightIcon = true,
    this.backgroundColor,
    this.onFocusChange,
    this.onSend,
  });

  @override
  State<DanmakuTextField> createState() => _DanmakuTextFieldState();
}

class _DanmakuTextFieldState extends State<DanmakuTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _textController = TextEditingController();
  }

  void _handleFocusChange() {
    widget.onFocusChange?.call(_focusNode.hasFocus);
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          widget.leftIcon
              ? Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: widget.iconColor,
                )
              : const SizedBox.shrink(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _textController,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.onSend == null ? null : (_) => _handleSend(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: '发送弹幕开发中...',
                hintStyle: TextStyle(
                  color: widget.textColor,
                  fontSize: 14,
                  height: 1.0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
            ),
          ),
          widget.rightIcon
              ? IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: widget.iconColor,
                  ),
                  onPressed: widget.onSend == null ? null : _handleSend,
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
