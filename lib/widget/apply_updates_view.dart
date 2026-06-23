import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/features/app/app_info_provider.dart';
import 'package:anime_flow/models/download_info.dart';
import 'package:anime_flow/models/version_download_state.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

class ApplyUpdatesView extends ConsumerStatefulWidget {
  final List<DownloadInfo> download;
  final String body;
  final Future<void> Function(String url, String fileName) onStartDownload;
  final VoidCallback onCancelDownload;
  final Box setting;

  const ApplyUpdatesView({
    super.key,
    required this.onStartDownload,
    required this.onCancelDownload,
    required this.download,
    required this.body,
    required this.setting,
  });

  @override
  ConsumerState<ApplyUpdatesView> createState() => _ApplyUpdatesViewState();
}

class _ApplyUpdatesViewState extends ConsumerState<ApplyUpdatesView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('有版本更新'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: widget.body,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                h3: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                listBullet: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                code: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final download = ref.watch(
                  appInfoProvider.select((s) => s.download),
                );
                if (download.isDownloading) {
                  return _DownloadProgressSection(download: download);
                }
                return _DownloadUrlSection(
                  downloadList: widget.download,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                widget.setting.put(StorageKey.autoUpdateKey, false);
                Navigator.of(context).pop();
              },
              child: const Text('取消自动更新'),
            ),
            Consumer(
              builder: (context, ref, _) {
                final isDownloading = ref.watch(
                  appInfoProvider.select((s) => s.download.isDownloading),
                );
                return Column(
                  children: [
                    TextButton(
                      onPressed: isDownloading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('稍后更新'),
                    ),
                    if (isDownloading)
                      TextButton(
                        onPressed: widget.onCancelDownload,
                        child: const Text('取消下载'),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          final downloadData =
                              widget.download[_selectedIndex];
                          await widget.onStartDownload(
                            downloadData.url,
                            downloadData.fileName,
                          );
                        },
                        child: const Text('立即更新'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DownloadProgressSection extends StatelessWidget {
  const _DownloadProgressSection({required this.download});

  final VersionDownloadState download;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '安装包会在GitHub仓库中下载，国内网络速度较慢，请使用代理改善网络',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '正在下载...',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${(download.progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: download.progress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        if (download.totalBytes > 0)
          Text(
            '${Utils.formatBytes(download.receivedBytes)} / ${Utils.formatBytes(download.totalBytes)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _DownloadUrlSection extends StatelessWidget {
  const _DownloadUrlSection({
    required this.downloadList,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DownloadInfo> downloadList;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (downloadList.length > 1)
          Text(
            '请选择下载地址:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        if (downloadList.length > 1) const SizedBox(height: 8),
        ...List.generate(downloadList.length, (index) {
          final data = downloadList[index];
          final isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  if (downloadList.length > 1) ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Utils.formatBytes(data.size),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
