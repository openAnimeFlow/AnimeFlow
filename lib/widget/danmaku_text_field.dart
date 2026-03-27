
import 'package:flutter/material.dart';

/// 弹幕输入框
class DanmakuTextField extends StatelessWidget {
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool leftIcon;
  final bool rightIcon;

  const DanmakuTextField(
      {super.key,
        this.iconColor,
        this.textColor,
        this.leftIcon = true,
        this.rightIcon = true,
        this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          leftIcon
              ? Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: iconColor,
          )
              : const SizedBox.shrink(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 14,
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: '发送弹幕开发中...',
                hintStyle: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
            ),
          ),
          rightIcon
              ? IconButton(
            icon: Icon(
              Icons.send_rounded,
              size: 20,
              color: iconColor,
            ),
            onPressed: () {
              // 发送弹幕逻辑
            },
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}