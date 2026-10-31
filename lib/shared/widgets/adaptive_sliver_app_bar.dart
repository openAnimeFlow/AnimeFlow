import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// 吸顶时根据设置显示磨砂背景的应用栏。
class AdaptiveSliverAppBar extends StatelessWidget {
  const AdaptiveSliverAppBar({
    super.key,
    required this.title,
    required this.flexibleSpace,
    required this.expandedHeight,
    required this.isPinned,
    required this.glassStyle,
    this.toolbarHeight = kToolbarHeight,
    this.bottom,
  });

  final Widget title;
  final Widget flexibleSpace;
  final double expandedHeight;
  final bool isPinned;
  final bool glassStyle;
  final double toolbarHeight;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final glassHeight = MediaQuery.paddingOf(context).top +
        toolbarHeight +
        (bottom?.preferredSize.height ?? 0);
    return SliverAppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: title,
      toolbarHeight: toolbarHeight,
      pinned: true,
      backgroundColor: glassStyle ? Colors.transparent : null,
      surfaceTintColor: glassStyle ? Colors.transparent : null,
      forceMaterialTransparency: glassStyle,
      elevation: glassStyle ? 0 : (isPinned ? 4.0 : 0.0),
      scrolledUnderElevation: glassStyle ? 0 : null,
      forceElevated: !glassStyle && isPinned,
      expandedHeight: expandedHeight,
      bottom: bottom,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          flexibleSpace,
          if (glassStyle && isPinned)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: glassHeight,
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
