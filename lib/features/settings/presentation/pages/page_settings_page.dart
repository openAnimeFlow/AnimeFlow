import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/startup_page.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
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
  late bool _glassNavigationStyle;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startupPage = AppSettings.startupPage;
    _collectionType = AppSettings.defaultCollectionType;
    _glassNavigationStyle = AppSettings.glassNavigationStyle;
  }

  Future<void> _setGlassNavigationStyle(bool value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppSettings.setGlassNavigationStyle(value);
      if (mounted) setState(() => _glassNavigationStyle = value);
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

  Widget _buildSelectionMenu<T>({
    required String tooltip,
    required Iterable<T> options,
    required T selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelected,
  }) {
    final colors = Theme.of(context).colorScheme;
    return JellyMenu<T>(
      tooltip: tooltip,
      enabled: !_saving,
      triggerResizeDuration: const Duration(milliseconds: 220),
      triggerResizeAlignment: AlignmentDirectional.centerEnd,
      triggerBuilder: (context, open) => TextButton(
        onPressed: open,
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                labelOf(selected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      menuBuilder: (context, select) => SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in options)
                MenuItemButton(
                  trailingIcon: option == selected
                      ? Icon(Icons.check, size: 18, color: colors.primary)
                      : null,
                  onPressed: _saving || option == selected
                      ? null
                      : () => select(option),
                  child: Text(labelOf(option)),
                ),
            ],
          ),
        ),
      ),
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = ref.watch(settingsLayoutProvider);
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
      child: SettingsPageBuilder(
          builder: (context) => Scaffold(
                extendBodyBehindAppBar: true,
                appBar: SettingsAppBar(
                  title: Text(l10n.pageSettings),
                  automaticallyImplyLeading: !wide,
                ),
                body: ListView(
                  padding: (EdgeInsets.fromLTRB(
                          10, 0, 10, 16 + MediaQuery.paddingOf(context).bottom))
                      .add(EdgeInsets.only(
                          top: SettingsPageBuilder.topInsetOf(context))),
                  children: [
                    SwitchListTile(
                      title: Text(l10n.glassNavigationStyle),
                      subtitle: Text(l10n.glassNavigationStyleDescription),
                      value: _glassNavigationStyle,
                      onChanged: _saving ? null : _setGlassNavigationStyle,
                    ),
                    ListTile(
                      title: Text(l10n.startupPage),
                      subtitle: Text(l10n.startupPageDescription),
                      trailing: _buildSelectionMenu<StartupPage>(
                        options: StartupPage.values,
                        selected: _startupPage,
                        labelOf: label,
                        tooltip: l10n.startupPage,
                        onSelected: _selectPage,
                      ),
                    ),
                    ListTile(
                      title: Text(l10n.defaultCollectionCategory),
                      subtitle: Text(l10n.defaultCollectionCategoryDescription),
                      trailing: _buildSelectionMenu<CollectType>(
                        options:
                            CollectType.values.where((type) => type.isCollected),
                        selected: _collectionType,
                        labelOf: collectionLabel,
                        tooltip: l10n.defaultCollectionCategory,
                        onSelected: _selectCollection,
                      ),
                    ),
                  ],
                ),
              )),
    );
  }
}
