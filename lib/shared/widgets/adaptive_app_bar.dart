import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// 支持磨砂背景的固定顶部栏。
///
/// 并在滚动内容内预留顶部栏和系统安全区的高度。
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    super.key,
    required this.glassStyle,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.backgroundColor,
    this.toolbarHeight = kToolbarHeight,
  });

  final bool glassStyle;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final Color? backgroundColor;
  final double toolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
        title: title,
        leading: leading,
        actions: actions,
        bottom: bottom,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        toolbarHeight: toolbarHeight,
        backgroundColor: glassStyle ? Colors.transparent : backgroundColor,
        surfaceTintColor: glassStyle ? Colors.transparent : null,
        forceMaterialTransparency: glassStyle,
        elevation: glassStyle ? 0 : null,
        scrolledUnderElevation: glassStyle ? 0 : null,
        flexibleSpace: glassStyle
            ? IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              )
            : null,
      );
}
