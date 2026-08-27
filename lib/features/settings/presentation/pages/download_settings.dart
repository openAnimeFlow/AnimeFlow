import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:file_picker/file_picker.dart';
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
  late Future<String> _downloadDirectory;

  @override
  void initState() {
    super.initState();
    _downloadDanmaku = setting.get(
      DownloadKey.downloadDanmaku,
      defaultValue: true,
    );
    _maxParallelEpisodes = setting.get(
      DownloadKey.maxParallelEpisodes,
      defaultValue: 3,
    );
    _maxParallelSegments = setting.get(
      DownloadKey.maxParallelSegments,
      defaultValue: 5,
    );
    _downloadDirectory = _configuredDownloadDirectory();
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.downloadLocation),
                  subtitle: FutureBuilder<String>(
                    future: _downloadDirectory,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text(l10n.downloadLocationUnavailable);
                      }
                      return Text(
                        snapshot.data!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  trailing: SystemUtil.isDesktop
                      ? const Icon(Icons.drive_file_move_outline)
                      : null,
                  onTap: () => _handleDownloadLocationTap(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _configuredDownloadDirectory() async {
    try {
      final configured = setting.get(
        DownloadKey.downloadDirectory,
        defaultValue: '',
      );
      if (configured is String && configured.trim().isNotEmpty) {
        return configured.trim();
      }
    } catch (_) {}
    return DownloadManager.getDefaultDownloadDirectory();
  }

  Future<void> _selectDownloadDirectory(AppLocalizations l10n) async {
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.downloadLocation,
    );
    if (selected == null || selected.trim().isEmpty || !mounted) {
      return;
    }
    final directory = selected.trim();
    await setting.put(DownloadKey.downloadDirectory, directory);
    if (!mounted) {
      return;
    }
    setState(() {
      _downloadDirectory = Future<String>.value(directory);
    });
  }

  void _handleDownloadLocationTap(AppLocalizations l10n) {
    if (SystemUtil.isDesktop) {
      _selectDownloadDirectory(l10n);
      return;
    }
    NotificationToast.show(l10n.downloadLocationUnsupported);
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
          Row(
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
