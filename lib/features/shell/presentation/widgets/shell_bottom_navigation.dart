import 'package:anime_flow/features/shell/presentation/models/tab_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';

class ShellBottomNavigation extends StatelessWidget {
  const ShellBottomNavigation(
      {super.key,
      required this.tabs,
      required this.selectedIndex,
      required this.onSelected,
      this.avatar});
  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? avatar;

  List<NavigationDestination> _buildBarDestinations(
    ColorScheme colorScheme,
    String? avatar,
  ) {
    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      if (index == 2 && avatar != null) {
        return NavigationDestination(
          icon: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(50),
            url: avatar,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
          selectedIcon: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(50),
              url: avatar,
              width: 24,
              height: 24,
              fit: BoxFit.fill,
            ),
          ),
          label: tab.title,
        );
      }

      return NavigationDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.activeIcon, color: colorScheme.primary),
        label: tab.title,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: _buildBarDestinations(colorScheme, avatar),
    );
  }
}
