import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowsTitleBarVisibility {
  WindowsTitleBarVisibility._();

  static final ValueNotifier<bool> forceHidden = ValueNotifier(false);

  static void setForceHidden(bool hidden) {
    if (!Platform.isWindows) return;
    if (forceHidden.value != hidden) {
      forceHidden.value = hidden;
    }
  }

  static void reset() => setForceHidden(false);
}

/// Windows 自定义标题栏
class WindowsTitleBar extends StatefulWidget {
  final Widget? child;
  final Color? backgroundColor;
  final double height;
  final Widget? icon;
  final String? title;

  const WindowsTitleBar({
    super.key,
    this.child,
    this.backgroundColor,
    this.height = 35,
    this.title,
    this.icon,
  });

  @override
  State<WindowsTitleBar> createState() => _WindowsTitleBarState();
}

class _WindowsTitleBarState extends State<WindowsTitleBar> with WindowListener {
  bool _showTitleBar = true;
  bool _windowFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      WindowsTitleBarVisibility.forceHidden.addListener(_onForceHiddenChanged);
      _syncTitleBarVisibility();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
      WindowsTitleBarVisibility.forceHidden
          .removeListener(_onForceHiddenChanged);
    }
    super.dispose();
  }

  /// 取消强制隐藏后需从 [windowManager] 重新同步，避免 _windowFullScreen 残留为 true。
  void _onForceHiddenChanged() {
    if (WindowsTitleBarVisibility.forceHidden.value) {
      _applyTitleBarVisibility();
    } else {
      _syncTitleBarVisibility();
    }
  }

  void _applyTitleBarVisibility() {
    if (!mounted) return;
    final show =
        !_windowFullScreen && !WindowsTitleBarVisibility.forceHidden.value;
    if (_showTitleBar != show) {
      setState(() => _showTitleBar = show);
    }
  }

  Future<void> _syncTitleBarVisibility() async {
    _windowFullScreen = await windowManager.isFullScreen();
    _applyTitleBarVisibility();
  }

  @override
  void onWindowEnterFullScreen() {
    _windowFullScreen = true;
    _applyTitleBarVisibility();
  }

  @override
  void onWindowLeaveFullScreen() {
    _windowFullScreen = false;
    _applyTitleBarVisibility();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child ?? const SizedBox.shrink();
    if (!Platform.isWindows) {
      return content;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return DragToResizeArea(
      resizeEdgeSize: 6.0,
      enableResizeEdges: const [
        ResizeEdge.topLeft,
        ResizeEdge.top,
        ResizeEdge.topRight,
      ],
      child: Column(
        children: [
          if (_showTitleBar) _buildTitleBar(context, colorScheme),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, ColorScheme colorScheme) {
    final title = widget.title;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surfaceContainerHighest,
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
            child: WindowDragArea(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                spacing: 5,
                children: [
                  if (widget.icon != null) widget.icon!,
                  if (title != null)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WindowMinimizeButton(),
              WindowMaximizeButton(),
              WindowCloseButton(),
            ],
          ),
        ],
      ),
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
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
          WindowMinimizeButton(),
          WindowMaximizeButton(),
          WindowCloseButton(),
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

class _WindowMaximizeButtonState extends State<WindowMaximizeButton>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (!mounted || _isMaximized == maximized) return;
    setState(() => _isMaximized = maximized);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowLeaveFullScreen() {
    _syncMaximized();
  }

  @override
  Widget build(BuildContext context) {
    return WindowControlButton(
      icon: _isMaximized
          ? Icons.filter_none_rounded
          : Icons.crop_square_rounded,
      onPressed: () async {
        if (_isMaximized) {
          await windowManager.restore();
        } else {
          await windowManager.maximize();
        }
        await _syncMaximized();
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
