import 'dart:async';
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

  /// 点击发送或键盘「发送」时回调。
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
  late final FocusNode focusNode;
  late final TextEditingController textController;

  static const int sendCooldownSeconds = 5;

  int sendCooldownRemaining = 0;
  Timer? sendCooldownTimer;

  bool get sendLocked => widget.onSend != null && sendCooldownRemaining > 0;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.addListener(handleFocusChange);
    textController = TextEditingController();
  }

  void handleFocusChange() {
    widget.onFocusChange?.call(focusNode.hasFocus);
  }

  void handleSend() {
    if (sendLocked) return;
    final text = textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    textController.clear();
    FocusScope.of(context).unfocus();
    if (widget.onSend != null) {
      startSendCooldown();
    }
  }

  void startSendCooldown() {
    sendCooldownTimer?.cancel();
    setState(() {
      sendCooldownRemaining = sendCooldownSeconds;
    });
    sendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        sendCooldownRemaining--;
        if (sendCooldownRemaining <= 0) {
          sendCooldownRemaining = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    sendCooldownTimer?.cancel();
    focusNode.removeListener(handleFocusChange);
    focusNode.dispose();
    textController.dispose();
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
              focusNode: focusNode,
              controller: textController,
              textInputAction: TextInputAction.send,
              onSubmitted: (widget.onSend == null || sendLocked)
                  ? null
                  : (_) => handleSend(),
              style: const TextStyle(
                fontSize: 14,
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: sendLocked
                    ? '请等待 ${sendCooldownRemaining} 秒后再发…'
                    : '发送弹幕...',
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
                  onPressed: (widget.onSend == null || sendLocked)
                      ? null
                      : handleSend,
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
