import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 通知 Toast
class NotificationToast {
  NotificationToast._();

  static const Duration defaultDuration = Duration(seconds: 3);
  static const double defaultMaxWidth = 500;

  /// 从下往上滑入
  static WrapAnimation get bottomUpAnimation =>
      BotToast.defaultOption.text.wrapToastAnimation!;

  /// 从上往下滑入
  static WrapAnimation get topDownAnimation =>
      BotToast.defaultOption.simpleNotification.wrapToastAnimation!;

  static WrapAnimation _defaultAnimationFor(Alignment align) {
    return align.y >= 0 ? bottomUpAnimation : topDownAnimation;
  }

  static void show(
    String title,
    String message, {
    Duration duration = defaultDuration,
    double maxWidth = defaultMaxWidth,
    Alignment align = Alignment.bottomCenter,
    WrapAnimation? wrapToastAnimation,
  }) {
    final animation = wrapToastAnimation ?? _defaultAnimationFor(align);
    BotToast.showSimpleNotification(
      title: title,
      subTitle: message,
      align: align,
      duration: duration,
      wrapToastAnimation: (controller, cancel, child) {
        child = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        );
        return animation(controller, cancel, child);
      },
    );
  }
}
