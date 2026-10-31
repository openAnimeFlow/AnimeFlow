import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([PlayStateNotifier])
Future<void> showPlayerSettingsSheet({
  required BuildContext context,
  required String label,
  required Widget child,
  VoidCallback? onOpen,
  VoidCallback? onClose,
  bool forceSide = false,
}) async {
  final container = ProviderScope.containerOf(context);
  onOpen?.call();
  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: label,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = forceSide ||
                ref.watch(
                  playStateProvider.select((state) => state.isWideScreen),
                );
            return SlideTransition(
              position: Tween<Offset>(
                begin: isWideScreen ? const Offset(1, 0) : const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
    );
  } finally {
    if (context.mounted) onClose?.call();
  }
}

@Dependencies([PlayStateNotifier])
class PlayerSettingsSheet extends ConsumerStatefulWidget {
  const PlayerSettingsSheet({
    super.key,
    this.child,
    this.builder,
    this.forceSide = false,
    this.avoidKeyboard = false,
    this.initialSize = 0.75,
    this.snapSizes = const [0.35, 0.75, 0.95],
    this.closeOnMinExtent = false,
  }) : assert((child == null) != (builder == null));

  final Widget? child;
  final Widget Function(BuildContext context, ScrollController controller,
      bool isBottomSheet)? builder;
  final bool forceSide;
  final bool avoidKeyboard;
  final double initialSize;
  final List<double> snapSizes;
  final bool closeOnMinExtent;

  @override
  ConsumerState<PlayerSettingsSheet> createState() =>
      _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends ConsumerState<PlayerSettingsSheet> {
  static const _snapDuration = Duration(milliseconds: 250);

  final _sheetController = DraggableScrollableController();
  final _wideScrollController = ScrollController();
  bool _keyboardVisible = false;

  void _snapToNearestSize() {
    if (!_sheetController.isAttached ||
        (widget.forceSide || ref.read(playStateProvider).isWideScreen)) {
      return;
    }
    final size = _sheetController.size;
    final target = widget.snapSizes
        .reduce((a, b) => (a - size).abs() <= (b - size).abs() ? a : b);
    _sheetController.animateTo(
      target,
      duration: _snapDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _wideScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = widget.forceSide ||
        ref.watch(
          playStateProvider.select((state) => state.isWideScreen),
        );
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = widget.avoidKeyboard && !isWideScreen
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final keyboardVisible = keyboardInset > 0;
    if (keyboardVisible != _keyboardVisible) {
      _keyboardVisible = keyboardVisible;
      if (keyboardVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _keyboardVisible && _sheetController.isAttached) {
            _sheetController.animateTo(
              widget.snapSizes.last,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
    Widget buildSheet(ScrollController scrollController) => Material(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          borderRadius: isWideScreen
              ? const BorderRadius.horizontal(left: Radius.circular(16))
              : const BorderRadius.vertical(top: Radius.circular(16)),
          child: SafeArea(
            left: !isWideScreen,
            top: isWideScreen,
            child: Column(
              children: [
                SizedBox(
                  height: isWideScreen ? 0 : 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: isWideScreen
                        ? null
                        : (details) {
                            if (!_sheetController.isAttached) return;
                            _sheetController.jumpTo(
                              (_sheetController.size -
                                      _sheetController.pixelsToSize(
                                        details.delta.dy,
                                      ))
                                  .clamp(widget.snapSizes.first,
                                      widget.snapSizes.last),
                            );
                          },
                    // jumpTo 不触发内置吸附，拖动条松手时主动归位。
                    onVerticalDragEnd:
                        isWideScreen ? null : (_) => _snapToNearestSize(),
                    onVerticalDragCancel:
                        isWideScreen ? null : _snapToNearestSize,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // 内容在滚动视图内部留白，让滚动条保持在抽屉边缘。
                  child: PrimaryScrollController(
                    controller: scrollController,
                    child: widget.builder
                            ?.call(context, scrollController, !isWideScreen) ??
                        widget.child!,
                  ),
                ),
              ],
            ),
          ),
        );

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Align(
        alignment:
            isWideScreen ? Alignment.centerRight : Alignment.bottomCenter,
        child: SizedBox(
          width: isWideScreen ? LayoutConstant.playContentWidth : size.width,
          child: isWideScreen
              ? SizedBox(
                  height: size.height, child: buildSheet(_wideScrollController))
              : NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if (notification.depth == 0 &&
                        notification.shouldCloseOnMinExtent &&
                        notification.extent <= notification.minExtent) {
                      Navigator.of(context).maybePop();
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: widget.initialSize,
                    minChildSize: widget.snapSizes.first,
                    maxChildSize: widget.snapSizes.last,
                    snap: !keyboardVisible,
                    snapSizes: keyboardVisible ? null : widget.snapSizes,
                    snapAnimationDuration: _snapDuration,
                    expand: false,
                    shouldCloseOnMinExtent:
                        widget.closeOnMinExtent && !keyboardVisible,
                    builder: (context, scrollController) =>
                        buildSheet(scrollController),
                  ),
                ),
        ),
      ),
    );
  }
}
