import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadSettingsPage extends ConsumerStatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  ConsumerState<DownloadSettingsPage> createState() =>
      _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends ConsumerState<DownloadSettingsPage> {
  final setting = Storage.setting;
  late bool _downloadDanmaku;
  late int _maxParallelEpisodes;
  late int _maxParallelSegments;

  @override
  void initState() {
    super.initState();
    _downloadDanmaku = setting.get(
      DownloadKey.downloadDanmaku,
      defaultValue: true,
    );
    _maxParallelEpisodes = setting.get(
      DownloadKey.maxParallelEpisodes,
      defaultValue: 2,
    );
    _maxParallelSegments = setting.get(
      DownloadKey.maxParallelSegments,
      defaultValue: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.downloadSettings),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.downloadSettings,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.downloadDanmaku),
                  subtitle: Text(l10n.downloadDanmakuDescription),
                  value: _downloadDanmaku,
                  onChanged: (value) {
                    setState(() {
                      _downloadDanmaku = value;
                    });
                    setting.put(DownloadKey.downloadDanmaku, value);
                  },
                ),
                _buildConcurrencySetting(
                  title: l10n.downloadParallelEpisodes,
                  subtitle: l10n.downloadParallelEpisodesDescription,
                  maxValue: 5,
                  value: _maxParallelEpisodes,
                  onChanged: (value) {
                    setState(() {
                      _maxParallelEpisodes = value;
                    });
                    setting.put(DownloadKey.maxParallelEpisodes, value);
                    ref.read(downloadManagerProvider).maxParallelEpisodes =
                        value;
                  },
                ),
                _buildConcurrencySetting(
                  title: l10n.downloadParallelSegments,
                  subtitle: l10n.downloadParallelSegmentsDescription,
                  maxValue: 10,
                  value: _maxParallelSegments,
                  onChanged: (value) {
                    setState(() {
                      _maxParallelSegments = value;
                    });
                    setting.put(DownloadKey.maxParallelSegments, value);
                    ref.read(downloadManagerProvider).maxParallelSegments =
                        value;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConcurrencySetting({
    required String title,
    required String subtitle,
    required int value,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$value',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: maxValue.toDouble(),
            divisions: maxValue - 1,
            label: '$value',
            onChanged: (selected) => onChanged(selected.round()),
          ),
        ],
      ),
    );
  }
}
