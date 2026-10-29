import 'dart:ui';
import 'dart:math' as math;

import 'package:anime_flow/features/shell/presentation/models/tab_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// 悬浮在页面内容上方的磨砂胶囊导航。
class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.avatar,
  });

  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(40);
    final labelSize = Theme.of(context).textTheme.labelSmall?.fontSize ?? 11;
    final height =
        math.max(64.0, 52 + MediaQuery.textScalerOf(context).scale(labelSize));
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.76),
                  borderRadius: radius,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / tabs.length;
                    return Stack(
                      children: [
                        AnimatedPositionedDirectional(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          start: itemWidth * selectedIndex,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer
                                  .withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < tabs.length; i++)
                              Expanded(child: _destination(context, i)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int index) {
    final tab = tabs[index];
    final selected = index == selectedIndex;
    final colors = Theme.of(context).colorScheme;
    final foreground =
        selected ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    final icon = index == 2 && avatar != null
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  selected ? Border.all(color: foreground, width: 1.5) : null,
            ),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(50),
              url: avatar!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          )
        : Icon(selected ? tab.activeIcon : tab.icon,
            size: 23, color: foreground);
    return Semantics(
      label: tab.title,
      button: true,
      selected: selected,
      onTap: () => onSelected(index),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(27),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            onTap: () => onSelected(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 2),
                Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
