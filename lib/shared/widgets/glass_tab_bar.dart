import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// 磨砂胶囊标签栏，使用同一个控制器驱动标签和页面。
class GlassTabBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassTabBar(
      {super.key,
      required this.controller,
      required this.labels,
      this.isScrollable = false});

  final TabController controller;
  final List<String> labels;
  final bool isScrollable;
  static const double height = 50;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.76),
                  borderRadius: radius,
                  border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.45)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: controller,
                    isScrollable: isScrollable,
                    tabAlignment:
                        isScrollable ? TabAlignment.start : TabAlignment.fill,
                    tabs: [
                      for (final label in labels)
                        Tab(
                          child: Text(label.replaceAll('\n', '  '),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: colors.secondaryContainer.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    labelColor: colors.onSecondaryContainer,
                    unselectedLabelColor: colors.onSurfaceVariant,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
