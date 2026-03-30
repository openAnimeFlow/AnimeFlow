import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 自定义标题栏组件
class WindowsTitleBar extends ConsumerWidget {
  final Widget? child;
  final Color? backgroundColor;
  final double height;

  const WindowsTitleBar({
    super.key,
    this.child,
    this.backgroundColor,
    this.height = 35,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!SystemUtil.isDesktop) {
      return child ?? const SizedBox.shrink();
    }

    // 仅在播放页注册过 PlayController 时根据 Riverpod 全屏状态隐藏标题栏（勿用无 Rx 的 Obx）
    try {
      final fullscreen =
          ref.watch(playController.select((s) => s.isFullscreen));
      if (fullscreen) {
        return child ?? const SizedBox.shrink();
      }
    } catch (_) {
      // 不在播放页：始终显示标题栏
    }
    return _buildTitleBar(context, colorScheme);
  }

  Widget _buildTitleBar(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // 标题栏在顶部
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: WindowDragArea(),
              ),
              // 右侧窗口控制按钮
              WindowControlButtons(),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: child ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// 窗口拖拽区域组件
class WindowDragArea extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const WindowDragArea({
    super.key,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 窗口控制按钮组
class WindowControlButtons extends StatelessWidget {
  const WindowControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (SystemUtil.isDesktop) ...[
          const WindowMinimizeButton(),
          const WindowMaximizeButton(),
          const WindowCloseButton(),
        ]
      ],
    );
  }
}

/// 窗口最小化按钮
class WindowMinimizeButton extends StatelessWidget {
  const WindowMinimizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: Icons.remove_rounded,
      onPressed: () {
        windowManager.minimize();
      },
    );
  }
}

/// 窗口最大化/还原按钮
class WindowMaximizeButton extends StatefulWidget {
  const WindowMaximizeButton({super.key});

  @override
  State<WindowMaximizeButton> createState() => _WindowMaximizeButtonState();
}

class _WindowMaximizeButtonState extends State<WindowMaximizeButton> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: Icons.crop_square_rounded,
      onPressed: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.restore();
        } else {
          await windowManager.maximize();
        }
      },
    );
  }
}

/// 窗口关闭按钮
class WindowCloseButton extends StatelessWidget {
  const WindowCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: Icons.close_rounded,
      onPressed: () {
        windowManager.close();
      },
      isClose: true,
    );
  }
}

/// 窗口控制按钮基础组件
class WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;
  final double width;
  final double height;

  const WindowControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isClose = false,
    this.width = 46,
    this.height = 40,
  });

  @override
  State<WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<WindowControlButton> {
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
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
