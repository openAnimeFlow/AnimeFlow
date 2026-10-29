import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/shell/presentation/models/tab_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:anime_flow/core/utils/system_util.dart';

class ShellNavigationRail extends StatelessWidget {
  const ShellNavigationRail(
      {super.key,
      required this.tabs,
      required this.selectedIndex,
      required this.onSelected,
      required this.onSearch,
      required this.onSettings,
      this.avatar});
  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final String? avatar;

  List<NavigationRailDestination> _buildRailDestinations(
    ColorScheme colorScheme,
    String? avatar,
  ) {
    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;

      if (index == 2 && avatar != null) {
        return NavigationRailDestination(
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
              fit: BoxFit.cover,
            ),
          ),
          label: Text(tab.title),
        );
      }
      return NavigationRailDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.activeIcon, color: colorScheme.primary),
        label: Text(tab.title),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final desktop = SystemUtil.isDesktop;
    return NavigationRail(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedIndex: selectedIndex,
      groupAlignment: 1.0,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: FloatingActionButton(
          heroTag: 'main_search',
          elevation: 0,
          onPressed: onSearch,
          child: const Icon(Icons.search),
        ),
      ),
      trailing: Padding(
        padding: EdgeInsets.only(
          bottom: desktop ? 16 : MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              iconSize: 28,
              tooltip: l10n.settings,
              onPressed: onSettings,
            ),
          ],
        ),
      ),
      destinations: _buildRailDestinations(colorScheme, avatar),
    );
  }
}
