import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/download/application/download_directory/download_directory_platform.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadSettingsPage extends ConsumerStatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  ConsumerState<DownloadSettingsPage> createState() =>
      _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends ConsumerState<DownloadSettingsPage> {
  late bool _downloadDanmaku;
  late int _maxParallelEpisodes;
  late int _maxParallelSegments;
  late Future<String> _downloadDirectory;
  bool _selectingDirectory = false;

  late final DownloadDirectoryPlatform _directoryPlatform =
      DownloadDirectoryPlatformFactory.create();

  @override
  void initState() {
    super.initState();
    _downloadDanmaku = AppSettings.downloadDanmaku;
    _maxParallelEpisodes = AppSettings.downloadMaxParallelEpisodes;
    _maxParallelSegments = AppSettings.downloadMaxParallelSegments;
    _downloadDirectory = getConfiguredDownloadDirectory();
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
                    AppSettings.setDownloadDanmaku(value);
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
                    AppSettings.setDownloadMaxParallelEpisodes(value);
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
                    AppSettings.setDownloadMaxParallelSegments(value);
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
                  trailing: _selectingDirectory
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _directoryPlatform.supportsSelection
                          ? const Icon(Icons.drive_file_move_outline)
                          : null,
                  onTap: _selectingDirectory ||
                          !_directoryPlatform.supportsSelection
                      ? null
                      : () => _selectDownloadDirectory(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDownloadDirectory(AppLocalizations l10n) async {
    if (_selectingDirectory) return;
    if (!_directoryPlatform.supportsSelection) {
      NotificationToast.show(l10n.downloadLocationUnsupported);
      return;
    }
    setState(() => _selectingDirectory = true);
    try {
      final granted = await _directoryPlatform.requestAccess();
      if (!mounted) return;
      if (!granted) {
        NotificationToast.show(l10n.downloadLocationPermissionDenied);
        return;
      }
      final selected = await _directoryPlatform.selectDirectory(
        dialogTitle: l10n.downloadLocation,
      );
      if (selected == null || selected.trim().isEmpty || !mounted) return;
      final directory = selected.trim();
      try {
        await _directoryPlatform.verifyWritable(directory);
      } on DownloadDirectoryNotWritableException {
        if (mounted) {
          NotificationToast.show(l10n.downloadLocationNotWritable);
        }
        return;
      }
      if (!mounted) return;
      await _directoryPlatform.persistAccess(directory);
      if (!mounted) return;
      await AppSettings.setDownloadDirectory(directory);
      if (!mounted) return;
      setState(() {
        _downloadDirectory = Future<String>.value(directory);
      });
    } catch (error, stackTrace) {
      LiggLogger().e('修改资源下载位置失败', error: error, stackTrace: stackTrace);
      if (mounted) NotificationToast.show(l10n.downloadLocationSelectFailed);
    } finally {
      if (mounted) setState(() => _selectingDirectory = false);
    }
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
