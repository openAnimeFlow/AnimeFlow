import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 自定义标题栏组件
class WindowsTitleBar extends StatelessWidget {
  final Widget? child;
  final Color? backgroundColor;
  final double height;

  const WindowsTitleBar({
    super.key,
    this.child,
    this.backgroundColor,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    // 只在 Windows 平台显示自定义标题栏
    if (!Platform.isWindows) {
      return child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 子内容，添加顶部 padding 避免被标题栏遮挡
        if (child != null)
          Padding(
            padding: EdgeInsets.only(top: height),
            child: child!,
          ),
        // 自定义标题栏覆盖在顶层
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child:  GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        windowManager.startDragging();
                      },
                      onDoubleTap: () async {
                        if (await windowManager.isMaximized()) {
                          windowManager.restore();
                        } else {
                          windowManager.maximize();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                ),
                // 右侧窗口控制按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 最小化按钮
                    _WindowButton(
                      icon: Icons.remove,
                      onPressed: () {
                        windowManager.minimize();
                      },
                    ),
                    // 最大化/还原按钮
                    _WindowButton(
                      icon: Icons.crop_square,
                      onPressed: () async {
                        if (await windowManager.isMaximized()) {
                          windowManager.restore();
                        } else {
                          windowManager.maximize();
                        }
                      },
                    ),
                    // 关闭按钮
                    _WindowButton(
                      icon: Icons.close,
                      onPressed: () {
                        windowManager.close();
                      },
                      isClose: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 窗口控制按钮
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor = Colors.transparent;
    Color iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    if (widget.isClose) {
      if (_isHovered) {
        backgroundColor = Colors.red;
        iconColor = Colors.white;
      }
    } else {
      if (_isHovered) {
        backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: backgroundColor,
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
