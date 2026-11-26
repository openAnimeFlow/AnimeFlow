import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

class JellyMenuKeyboardAvoidance {
  /// 根据键盘弹出后剩余的空间调整展开方向。
  const JellyMenuKeyboardAvoidance.adaptive() : _minVisibleHeight = null;

  /// 保持展开方向，向下展开时只上移到能露出指定高度的位置。
  const JellyMenuKeyboardAvoidance.keepVisible(double height)
      : assert(height >= 0),
        _minVisibleHeight = height;

  final double? _minVisibleHeight;
}

typedef _MenuPlacement = ({
  Alignment anchor,
  Size available,
  Widget Function(Widget surface) positionMenu,
});

/// A trigger that morphs into a menu in the nearest overlay.
class JellyMenu<T> extends StatefulWidget {
  const JellyMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.menuBuilder,
    required this.onSelected,
    this.onOpenChanged,
    this.triggerColor,
    this.menuColor,
    this.elevation = 0,
    this.triggerResizeDuration = Duration.zero,
    this.triggerResizeAlignment = Alignment.center,
    this.enabled = true,
    this.barrierDismissible = true,
    this.keyboardAvoidance,
    this.preferredVerticalDirection,
    this.widthSpring = const SpringDescription(
      mass: 1,
      stiffness: 220,
      damping: 22,
    ),
    this.heightSpring = const SpringDescription(
      mass: 1,
      stiffness: 185,
      damping: 19,
    ),
    this.tooltip = '更多',
  }) : assert((trigger == null) != (triggerBuilder == null));

  /// 点击后展开菜单的组件。
  final Widget? trigger;

  /// 构建通过自身按钮回调打开菜单的触发组件。
  final Widget Function(BuildContext context, VoidCallback? open)?
      triggerBuilder;

  /// 触发组件的背景色，省略时使用主题的 surfaceContainerHigh。
  final Color? triggerColor;

  /// 菜单展开后的背景色，省略时使用主题的 surfaceContainerHigh。
  final Color? menuColor;

  /// 触发组件和展开菜单的阴影高度。
  final double elevation;

  /// 菜单收起后，触发组件在内容尺寸变化时的动画时长。
  final Duration triggerResizeDuration;

  /// 触发组件对齐内容的位置。
  final AlignmentGeometry triggerResizeAlignment;

  /// 是否允许打开菜单。
  final bool enabled;

  /// 是否允许点按菜单外部来收起菜单。
  final bool barrierDismissible;

  /// 表单菜单在键盘弹出时的定位方式。
  final JellyMenuKeyboardAvoidance? keyboardAvoidance;

  /// 控制菜单宽度变化的弹簧参数，也适用于动画中途反转。
  final SpringDescription widthSpring;

  /// 控制菜单高度变化的弹簧参数。
  final SpringDescription heightSpring;

  /// 菜单优先向哪个垂直方向展开，空间不足时可向另一侧展开。
  final VerticalDirection? preferredVerticalDirection;

  /// 构建菜单内容，调用 select 选择一项并关闭菜单。
  final Widget Function(BuildContext context, ValueChanged<T> select)
      menuBuilder;

  /// 选择菜单项时回调，参数为选中的值。
  final ValueChanged<T> onSelected;

  /// 菜单开始展开时回调 true，开始收起或展开期间被移除时回调 false。
  final ValueChanged<bool>? onOpenChanged;

  /// 触发组件的提示文案。
  final String tooltip;

  static EdgeInsets itemPadding(BuildContext context) {
    final vertical = switch (MediaQuery.sizeOf(context).width) {
      < 600 => 10.0,
      < 900 => 16.0,
      _ => 20.0,
    };
    return EdgeInsets.symmetric(horizontal: 14, vertical: vertical);
  }

  @override
  State<JellyMenu<T>> createState() => _JellyMenuState<T>();
}

class _JellyMenuState<T> extends State<JellyMenu<T>>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final width = AnimationController.unbounded(vsync: this);
  late final height = AnimationController.unbounded(vsync: this);
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _targetKey = GlobalKey();
  Alignment _anchor = Alignment.topRight;
  Rect _initialTarget = Rect.zero;
  Size _initialOverlaySize = Size.zero;
  Size _triggerSize = Size.zero;
  Widget? _overlayTrigger;
  bool open = false;
  int _animationGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.keyboardAvoidance != null) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didUpdateWidget(covariant JellyMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final avoidsKeyboard = widget.keyboardAvoidance != null;
    if (avoidsKeyboard == (oldWidget.keyboardAvoidance != null)) return;
    if (avoidsKeyboard) {
      WidgetsBinding.instance.addObserver(this);
    } else {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void didChangeMetrics() {
    if (_portal.isShowing) setState(() {});
  }

  Widget _buildTrigger(BuildContext context) =>
      widget.triggerBuilder?.call(context, widget.enabled ? _open : null) ??
      widget.trigger!;

  void _open() {
    if (!widget.enabled || open) return;
    if (_portal.isShowing) {
      toggle(true);
      return;
    }
    final target = _targetKey.currentContext!.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    _triggerSize = target.size;
    if (widget.triggerResizeDuration != Duration.zero) {
      _overlayTrigger = _buildTrigger(context);
    }
    final origin = target.localToGlobal(Offset.zero, ancestor: overlay);
    final right = overlay.size.width - origin.dx;
    final left = origin.dx + target.size.width;
    final below = overlay.size.height - origin.dy;
    final above = origin.dy + target.size.height;
    final towardRight = right >= left;
    final minimumSpace = target.size.height * 2;
    final towardBottom = switch (widget.preferredVerticalDirection) {
      VerticalDirection.down => below >= minimumSpace || below >= above,
      VerticalDirection.up => !(above >= minimumSpace || above >= below),
      null => below >= above,
    };
    _anchor = Alignment(towardRight ? -1 : 1, towardBottom ? -1 : 1);
    _initialTarget = origin & _triggerSize;
    _initialOverlaySize = overlay.size;
    _portal.show();
    toggle(true);
  }

  Future<void> toggle(bool next) async {
    if (open == next) return;
    final generation = ++_animationGeneration;
    setState(() => open = next);
    widget.onOpenChanged?.call(next);

    Future<void> move(
        AnimationController controller, SpringDescription spring) async {
      final target = next ? 1.0 : 0.0;
      if (MediaQuery.disableAnimationsOf(context)) {
        controller.value = target;
        return;
      }
      await controller
          .animateWith(SpringSimulation(
            spring,
            controller.value,
            target,
            controller.velocity,
          ))
          .orCancel;
      if (mounted && generation == _animationGeneration) {
        controller.value = target;
      }
    }

    try {
      await Future.wait([
        move(width, widget.widthSpring),
        move(height, widget.heightSpring),
      ]);
      if (mounted && generation == _animationGeneration && !open) {
        _portal.hide();
        setState(() => _overlayTrigger = null);
      }
    } on TickerCanceled {
      // A new animation or disposal superseded this one.
    }
  }

  void select(T value) {
    if (!open) return;
    toggle(false);
    widget.onSelected(value);
  }

  @override
  void dispose() {
    if (open) widget.onOpenChanged?.call(false);
    if (widget.keyboardAvoidance != null) {
      WidgetsBinding.instance.removeObserver(this);
    }
    width.dispose();
    height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final triggerColor = widget.triggerColor ?? colors.surfaceContainerHigh;
    final triggerChild = _buildTrigger(context);
    final trigger = widget.triggerResizeDuration == Duration.zero
        ? triggerChild
        : AnimatedSize(
            alignment: widget.triggerResizeAlignment,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : widget.triggerResizeDuration,
            curve: Curves.easeInOutCubic,
            child: SizedBox.fromSize(
              size: _portal.isShowing ? _triggerSize : null,
              child: _overlayTrigger ?? triggerChild,
            ),
          );
    final triggerControl = widget.triggerBuilder != null
        ? trigger
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: !widget.enabled,
            onTap: _open,
            child: trigger,
          );
    final target = CompositedTransformTarget(
      key: _targetKey,
      link: _link,
      child: Opacity(
        opacity: _portal.isShowing ? 0 : 1,
        child: Material(
          elevation: widget.elevation,
          color: triggerColor,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: Tooltip(
            message: widget.tooltip,
            child: triggerControl,
          ),
        ),
      ),
    );
    final keyboardAvoidance = widget.keyboardAvoidance;
    if (keyboardAvoidance != null) {
      return OverlayPortal.overlayChildLayoutBuilder(
        controller: _portal,
        overlayChildBuilder: (context, layout) => _buildOverlay(
          triggerColor,
          triggerChild,
          _keyboardPlacement(context, layout, keyboardAvoidance),
        ),
        child: target,
      );
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) =>
          _buildOverlay(triggerColor, triggerChild, _followerPlacement()),
      child: target,
    );
  }

  _MenuPlacement _followerPlacement() {
    final anchor = _anchor;
    return (
      anchor: anchor,
      available: _availableSpace(
        _initialTarget,
        _initialOverlaySize,
        anchor,
        anchor.y < 0
            ? _initialOverlaySize.height - _initialTarget.top
            : _initialTarget.bottom,
      ),
      positionMenu: (surface) => Align(
            alignment: Alignment.topLeft,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: anchor,
              followerAnchor: anchor,
              child: surface,
            ),
          ),
    );
  }

  _MenuPlacement _keyboardPlacement(
    BuildContext context,
    OverlayChildLayoutInfo layout,
    JellyMenuKeyboardAvoidance keyboardAvoidance,
  ) {
    final target = MatrixUtils.transformRect(
      layout.childPaintTransform,
      Offset.zero & layout.childSize,
    );
    final overlaySize = layout.overlaySize;
    final view = View.of(context);
    final keyboardInset = view.viewInsets.bottom / view.devicePixelRatio;
    var overlayTop = 0.0;
    var visibleBottom = overlaySize.height;
    if (keyboardInset > 0) {
      final overlay =
          Overlay.of(context).context.findRenderObject()! as RenderBox;
      overlayTop = overlay.localToGlobal(Offset.zero).dy;
      final keyboardTop = view.physicalSize.height / view.devicePixelRatio -
          keyboardInset -
          overlayTop;
      visibleBottom = keyboardTop.clamp(0.0, overlaySize.height);
    }
    final anchorHeight = keyboardAvoidance._minVisibleHeight;
    final initiallyOpensDown = _anchor.y < 0;
    var latestTop = visibleBottom;
    if (keyboardInset > 0 && anchorHeight != null && initiallyOpensDown) {
      final safeTop =
          (view.viewPadding.top / view.devicePixelRatio - overlayTop)
              .clamp(0.0, visibleBottom);
      latestTop = (visibleBottom - anchorHeight).clamp(safeTop, visibleBottom);
    }
    final top = target.top.clamp(0.0, latestTop);
    final bottom = target.bottom.clamp(0.0, visibleBottom);
    final opensDown = keyboardInset > 0 && anchorHeight == null
        ? visibleBottom - top >= bottom
        : initiallyOpensDown;
    final opensRight = _anchor.x < 0;
    final anchor = Alignment(_anchor.x, opensDown ? -1 : 1);
    return (
      anchor: anchor,
      available: _availableSpace(
        target,
        overlaySize,
        anchor,
        opensDown ? visibleBottom - top : bottom,
      ),
      positionMenu: (surface) => Positioned(
            left: opensRight ? target.left : null,
            right: opensRight ? null : overlaySize.width - target.right,
            top: opensDown ? top : null,
            bottom: opensDown ? null : overlaySize.height - bottom,
            child: surface,
          ),
    );
  }

  Size _availableSpace(
      Rect target, Size overlaySize, Alignment anchor, double availableHeight) {
    final availableWidth =
        anchor.x < 0 ? overlaySize.width - target.left : target.right;
    return Size(
      availableWidth.clamp(0.0, overlaySize.width),
      availableHeight.clamp(0.0, overlaySize.height),
    );
  }

  Widget _buildOverlay(
    Color triggerColor,
    Widget trigger,
    _MenuPlacement placement,
  ) {
    final radius = _triggerSize.shortestSide / 2;
    return AnimatedBuilder(
      animation: Listenable.merge([width, height]),
      child: Builder(builder: (context) => widget.menuBuilder(context, select)),
      builder: (context, menu) {
        final colors = Theme.of(context).colorScheme;
        final reveal = ((height.value - .45) * 2.4).clamp(0.0, 1.0).toDouble();
        final surface = ConstrainedBox(
          constraints: BoxConstraints.loose(placement.available),
          child: Material(
            elevation: widget.elevation,
            color: Color.lerp(
              triggerColor,
              widget.menuColor ?? colors.surfaceContainerHigh,
              reveal,
            ),
            borderRadius:
                BorderRadius.circular(radius + (18 - radius) * reveal),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                _MenuSurface(
                  triggerSize: _triggerSize,
                  widthProgress: width.value,
                  heightProgress: height.value,
                  alignment: placement.anchor,
                  child: IgnorePointer(
                    ignoring: !open || reveal == 0,
                    child: ExcludeSemantics(
                      excluding: !open || reveal == 0,
                      child: Opacity(opacity: reveal, child: menu),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeFocus(
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity:
                              (1 - width.value * 3).clamp(0.0, 1.0).toDouble(),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child:
                                  open ? _overlayTrigger ?? trigger : trigger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return IgnorePointer(
          ignoring: !open,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ModalBarrier(
                color: Colors.black
                    .withValues(alpha: .12 * height.value.clamp(0.0, 1.0)),
                dismissible: widget.barrierDismissible,
                onDismiss: () => toggle(false),
                semanticsLabel:
                    MaterialLocalizations.of(context).modalBarrierDismissLabel,
              ),
              placement.positionMenu(surface),
            ],
          ),
        );
      },
    );
  }
}

/// Measures the menu at its natural size while animating the outer surface.
class _MenuSurface extends SingleChildRenderObjectWidget {
  const _MenuSurface({
    required this.triggerSize,
    required this.widthProgress,
    required this.heightProgress,
    required this.alignment,
    super.child,
  });

  final Size triggerSize;
  final double widthProgress;
  final double heightProgress;
  final Alignment alignment;

  @override
  _RenderMenuSurface createRenderObject(BuildContext context) =>
      _RenderMenuSurface(triggerSize, widthProgress, heightProgress, alignment);

  @override
  void updateRenderObject(
      BuildContext context, _RenderMenuSurface renderObject) {
    renderObject.update(triggerSize, widthProgress, heightProgress, alignment);
  }
}

class _RenderMenuSurface extends RenderShiftedBox {
  _RenderMenuSurface(
      this.triggerSize, this.widthProgress, this.heightProgress, this.alignment)
      : super(null);

  Size triggerSize;
  double widthProgress;
  double heightProgress;
  Alignment alignment;

  void update(Size size, double width, double height, Alignment newAlignment) {
    if (triggerSize == size &&
        widthProgress == width &&
        heightProgress == height &&
        alignment == newAlignment) {
      return;
    }
    triggerSize = size;
    widthProgress = width;
    heightProgress = height;
    alignment = newAlignment;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final initial = constraints.constrain(triggerSize);
    child!.layout(
      constraints.loosen().copyWith(minWidth: initial.width),
      parentUsesSize: true,
    );
    final menuSize = child!.size;
    size = constraints.constrain(Size(
      (initial.width + (menuSize.width - initial.width) * widthProgress)
          .clamp(0.0, double.infinity)
          .toDouble(),
      (initial.height + (menuSize.height - initial.height) * heightProgress)
          .clamp(0.0, double.infinity)
          .toDouble(),
    ));
    final parentData = child!.parentData! as BoxParentData;
    parentData.offset = alignment.alongOffset(
        Offset(size.width - menuSize.width, size.height - menuSize.height));
  }
}

enum _ProfileAction { color, username, copyLink }

@Preview(name: '右上角果冻菜单', group: 'JellyMenu', size: Size(360, 300))
Widget jellyMenuPreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(child: Text('L')),
                    Text('Ligg'),
                    Text('在线'),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: JellyMenu<_ProfileAction>(
                  trigger: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.more_vert),
                  ),
                  onSelected: (value) => debugPrint(value.name),
                  menuBuilder: (context, select) {
                    const items = [
                      (
                        value: _ProfileAction.color,
                        icon: Icons.palette_outlined,
                        label: '更改个人资料页颜色'
                      ),
                      (
                        value: _ProfileAction.username,
                        icon: Icons.alternate_email,
                        label: '更改用户名'
                      ),
                      (
                        value: _ProfileAction.copyLink,
                        icon: Icons.link,
                        label: '复制个人资料页链接'
                      ),
                    ];
                    final style = Theme.of(context).textTheme.labelLarge!;
                    return IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: style,
                                ),
                                onPressed: () => select(item.value),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(item.icon, size: 24),
                                    const SizedBox(width: 12),
                                    Flexible(
                                        child: Text(item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
