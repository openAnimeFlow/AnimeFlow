import 'dart:async';
import 'package:flutter/material.dart';

/// 弹幕输入框
class DanmakuTextField extends StatefulWidget {
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool inputVisible;
  final double? height;
  final bool showCloseButton;

  /// 输入框聚焦状态变化（`true` 获得焦点，`false` 失去焦点）
  final ValueChanged<bool>? onFocusChange;

  /// 点击发送或键盘「发送」时回调。
  final ValueChanged<String>? onSend;

  /// 点击右侧弹幕开关按钮时回调。
  final VoidCallback? onClose;

  const DanmakuTextField({
    super.key,
    this.iconColor,
    this.textColor,
    this.height,
    this.showCloseButton = true,
    this.inputVisible = true,
    this.backgroundColor,
    this.onFocusChange,
    this.onSend,
    this.onClose,
  });

  @override
  State<DanmakuTextField> createState() => _DanmakuTextFieldState();
}

class _DanmakuTextFieldState extends State<DanmakuTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode focusNode;
  late final TextEditingController textController;
  late final AnimationController inputAnimationController;
  late final Animation<double> inputAnimation;

  static const int sendCooldownSeconds = 5;
  static const Duration closeAnimationDuration = Duration(milliseconds: 220);
  static const double defaultHeight = 36;
  static const double collapsedWidth = 44;

  int sendCooldownRemaining = 0;
  Timer? sendCooldownTimer;

  bool get sendLocked => widget.onSend != null && sendCooldownRemaining > 0;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.addListener(handleFocusChange);
    textController = TextEditingController();
    inputAnimationController = AnimationController(
      vsync: this,
      duration: closeAnimationDuration,
      value: widget.inputVisible ? 1 : 0,
    );
    inputAnimation = CurvedAnimation(
      parent: inputAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant DanmakuTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputVisible == oldWidget.inputVisible) return;
    if (widget.inputVisible) {
      inputAnimationController.forward();
    } else {
      inputAnimationController.reverse();
    }
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

  void handleClose() {
    FocusScope.of(context).unfocus();
    widget.onClose?.call();
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
    inputAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth - 16 : 150.0;
        final closeButtonWidth = widget.showCloseButton ? collapsedWidth : 0.0;
        final inputWidth =
            (maxWidth - closeButtonWidth).clamp(0.0, double.infinity);
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: widget.height ?? defaultHeight,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizeTransition(
                  axis: Axis.horizontal,
                  sizeFactor: inputAnimation,
                  alignment: Alignment.centerRight,
                  child: FadeTransition(
                    opacity: inputAnimation,
                    child: SizedBox(
                      width: inputWidth,
                      child: TextField(
                        focusNode: focusNode,
                        controller: textController,
                        textInputAction: TextInputAction.send,
                        textAlignVertical: TextAlignVertical.center,
                        onSubmitted: (widget.onSend == null || sendLocked)
                            ? null
                            : (_) => handleSend(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.0,
                        ),
                        decoration: InputDecoration(
                          hintText: sendLocked
                              ? '请等待 $sendCooldownRemaining 秒后再发…'
                              : '发送弹幕...',
                          hintStyle: TextStyle(
                            color: widget.textColor,
                            fontSize: 14,
                            height: 1.0,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showCloseButton)
                  IconButton(
                    tooltip: widget.inputVisible ? '关闭弹幕' : '开启弹幕',
                    constraints: const BoxConstraints.tightFor(
                      width: collapsedWidth,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.inputVisible
                          ? Icons.subtitles_outlined
                          : Icons.subtitles_off_outlined,
                      size: 20,
                      color: widget.iconColor,
                    ),
                    onPressed: widget.onClose == null ? null : handleClose,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
