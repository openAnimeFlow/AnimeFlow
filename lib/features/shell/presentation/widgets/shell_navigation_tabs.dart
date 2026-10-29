import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/shell/presentation/models/tab_item.dart';
import 'package:material_ui/material_ui.dart';

List<TabItem> shellNavigationTabs(AppLocalizations l10n) => [
      TabItem(
        title: l10n.recommend,
        icon: Icons.smart_display_outlined,
        activeIcon: Icons.smart_display_rounded,
      ),
      TabItem(
        title: l10n.rankingTitle,
        icon: Icons.leaderboard_outlined,
        activeIcon: Icons.leaderboard_rounded,
      ),
      TabItem(
        title: l10n.mine,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];
