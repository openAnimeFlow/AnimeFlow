import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 通知 Toast
class NotificationToast {
  NotificationToast._();

  static const Duration defaultDuration = Duration(seconds: 3);
  static const BorderRadius defaultBorderRadius = BorderRadius.all(Radius.circular(12));

  /// 从下往上滑入
  static WrapAnimation get bottomUpAnimation =>
      BotToast.defaultOption.text.wrapToastAnimation!;

  /// 从上往下滑入
  static WrapAnimation get topDownAnimation =>
      BotToast.defaultOption.simpleNotification.wrapToastAnimation!;

  static WrapAnimation _defaultAnimationFor(Alignment align) {
    return align.y >= 0 ? bottomUpAnimation : topDownAnimation;
  }

  static BorderRadius _borderRadius(ThemeData theme, BorderRadius borderRadius) {
    final shape = theme.cardTheme.shape;
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius.resolve(TextDirection.ltr);
    }
    return borderRadius;
  }

  static void show(
    String title,
    String message, {
    BorderRadius borderRadius = defaultBorderRadius,
    Duration duration = defaultDuration,
    double maxWidth = 500.0,
    String iconPath = AssetsPathConstants.logo,
    Alignment align = Alignment.bottomCenter,
    WrapAnimation? wrapToastAnimation,
  }) {
    final animation = wrapToastAnimation ?? _defaultAnimationFor(align);
    BotToast.showCustomNotification(
      align: align,
      duration: duration,
      crossPage: false,
      onlyOne: true,
      toastBuilder: (_) => Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              color:
                  theme.cardTheme.color ?? colorScheme.surfaceContainerHighest,
              elevation: theme.cardTheme.elevation ?? 1,
              shape: RoundedRectangleBorder(
                borderRadius: _borderRadius(theme, borderRadius),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Image.asset(iconPath),
                title: Text(title),
                subtitle: Text(message),
              ),
            ),
          );
        },
      ),
      wrapToastAnimation: (controller, cancel, child) {
        return animation(controller, cancel, child);
      },
    );
  }
}
