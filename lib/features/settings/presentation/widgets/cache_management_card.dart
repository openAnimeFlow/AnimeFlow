import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/cache/cache_usage_service.dart';
import 'package:anime_flow/core/network/image/image_cache_service.dart';
import 'package:anime_flow/features/settings/presentation/widgets/cache_usage_panel.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';

class CacheManagementCard extends StatefulWidget {
  const CacheManagementCard({super.key});

  @override
  State<CacheManagementCard> createState() => _CacheManagementCardState();
}

class _CacheManagementCardState extends State<CacheManagementCard> {
  final _images = ImageCacheService();
  final _data = CacheUsageService();
  late Future<CacheUsage> _usage = _measure();
  Set<CacheCategory> _selected = CacheCategory.values.toSet();
  bool _requested = false;
  bool _clearing = false;

  Future<CacheUsage> _measure() async {
    final (images, data) =
        await (_images.sizeInBytes(), _data.dataSizesInBytes()).wait;
    return CacheUsage({CacheCategory.images: images, ...data});
  }

  void _refreshUsage() {
    final usage = _measure();
    setState(() {
      _usage = usage;
    });
  }

  Future<void> _clearSelected() async {
    if (_requested || _selected.isEmpty) return;
    final selected = {..._selected};
    setState(() => _requested = true);
    try {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              icon: const Icon(Icons.cleaning_services_rounded),
              title: Text(l10n.clearSelectedCacheTitle),
              content: Text(
                  '${selected.map((key) => cacheCategoryLabel(key, l10n)).join('、')}\n\n${l10n.clearSelectedCacheDescription}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.clearSelectedCache)),
              ],
            );
          });
      if (confirmed != true || !mounted) return;
      setState(() => _clearing = true);
      try {
        await Future.wait([
          if (selected.contains(CacheCategory.images)) _images.clear(),
          _data.clearData(selected),
        ]);
        if (mounted) {
          NotificationToast.show(
              AppLocalizations.of(context).selectedCacheCleared);
        }
      } catch (_) {
        if (mounted) {
          NotificationToast.show(
              AppLocalizations.of(context).selectedCacheClearFailed);
        }
      } finally {
        if (mounted) _refreshUsage();
      }
    } finally {
      if (mounted) {
        setState(() {
          _requested = false;
          _clearing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<CacheUsage>(
          future: _usage,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Icon(Icons.donut_large_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(l10n.cacheUsageTitle,
                            style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                        tooltip: l10n.reload,
                        onPressed: loading || _requested ? null : _refreshUsage,
                        icon: const Icon(Icons.refresh_rounded)),
                  ]),
                  if (snapshot.hasError && !loading)
                    Text(l10n.imageCacheSizeFailed,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  CacheUsagePanel(
                    usage: snapshot.data ?? CacheUsage({}),
                    selected: _selected,
                    loading: loading,
                    refreshToken: _usage,
                    busy: loading || snapshot.hasError || _requested,
                    clearing: _clearing,
                    onSelectionChanged: (selected) =>
                        setState(() => _selected = selected),
                    onClear: _clearSelected,
                  ),
                ]);
          }),
    );
  }
}
