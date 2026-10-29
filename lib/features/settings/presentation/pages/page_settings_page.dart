import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/startup_page.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/models/enums/collect_type.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class PageSettingsPage extends ConsumerStatefulWidget {
  const PageSettingsPage({super.key});

  @override
  ConsumerState<PageSettingsPage> createState() => _PageSettingsPageState();
}

class _PageSettingsPageState extends ConsumerState<PageSettingsPage> {
  late StartupPage _startupPage;
  late CollectType _collectionType;
  late bool _glassNavigationBar;
  bool _saving = false;
  bool _isMenuOpen = false;
  bool _isCollectionMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _startupPage = AppSettings.startupPage;
    _collectionType = AppSettings.defaultCollectionType;
    _glassNavigationBar = AppSettings.glassNavigationBar;
  }

  Future<void> _setGlassNavigationBar(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppSettings.setGlassNavigationBar(value);
      if (mounted) setState(() => _glassNavigationBar = value);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.saveFailed, title: l10n.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectCollection(CollectType type) async {
    if (type == _collectionType || _saving) return;
    setState(() => _saving = true);
    try {
      await AppSettings.setDefaultCollectionType(type);
      if (mounted) setState(() => _collectionType = type);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.saveFailed, title: l10n.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectPage(StartupPage page) async {
    if (page == _startupPage || _saving) return;
    setState(() => _saving = true);
    try {
      await AppSettings.setStartupPage(page);
      if (mounted) setState(() => _startupPage = page);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.saveFailed, title: l10n.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = ref.watch(settingsLayoutProvider);
    final primary = Theme.of(context).colorScheme.primary;
    String label(StartupPage page) => switch (page) {
          StartupPage.recommend => l10n.recommend,
          StartupPage.ranking => l10n.rankingTitle,
          StartupPage.user => l10n.mine,
        };
    String collectionLabel(CollectType type) => switch (type) {
          CollectType.planToWatch => l10n.collectionPlanToWatch,
          CollectType.watched => l10n.collectionWatched,
          CollectType.watching => l10n.collectionWatching,
          CollectType.onHold => l10n.collectionOnHold,
          CollectType.abandoned => l10n.collectionAbandoned,
          CollectType.none => throw ArgumentError.value(type),
        };
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.pageSettings),
          automaticallyImplyLeading: !wide,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
          children: [
            SwitchListTile(
              title: Text(l10n.glassNavigationBar),
              subtitle: Text(l10n.glassNavigationBarDescription),
              value: _glassNavigationBar,
              onChanged: _saving ? null : _setGlassNavigationBar,
            ),
            ListTile(
              title: Text(l10n.startupPage),
              subtitle: Text(l10n.startupPageDescription),
              trailing: AbsorbPointer(
                absorbing: _saving,
                child: DropDownMenu<StartupPage>(
                  items: StartupPage.values,
                  selectedItem: _startupPage,
                  tooltip: l10n.startupPage,
                  onOpenedChanged: (isOpen) =>
                      setState(() => _isMenuOpen = isOpen),
                  buttonBuilder: (context, selectedItem) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label(selectedItem!),
                          style: TextStyle(color: primary)),
                      AnimatedRotation(
                        turns: _isMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(Icons.arrow_drop_down, color: primary),
                      ),
                    ],
                  ),
                  itemBuilder: (context, page, isSelected) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        child: isSelected
                            ? Icon(Icons.check, size: 18, color: primary)
                            : null,
                      ),
                      Text(label(page)),
                    ],
                  ),
                  onSelected: _selectPage,
                ),
              ),
            ),
            ListTile(
              title: Text(l10n.defaultCollectionCategory),
              subtitle: Text(l10n.defaultCollectionCategoryDescription),
              trailing: AbsorbPointer(
                absorbing: _saving,
                child: DropDownMenu<CollectType>(
                  items: CollectType.values
                      .where((type) => type.isCollected)
                      .toList(),
                  selectedItem: _collectionType,
                  tooltip: l10n.defaultCollectionCategory,
                  onOpenedChanged: (isOpen) =>
                      setState(() => _isCollectionMenuOpen = isOpen),
                  buttonBuilder: (context, selectedItem) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(collectionLabel(selectedItem!),
                          style: TextStyle(color: primary)),
                      AnimatedRotation(
                        turns: _isCollectionMenuOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(Icons.arrow_drop_down, color: primary),
                      ),
                    ],
                  ),
                  itemBuilder: (context, type, isSelected) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 24,
                          child: isSelected
                              ? Icon(Icons.check, size: 18, color: primary)
                              : null),
                      Text(collectionLabel(type)),
                    ],
                  ),
                  onSelected: _selectCollection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
