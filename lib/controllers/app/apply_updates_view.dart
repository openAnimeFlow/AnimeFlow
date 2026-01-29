import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';

class ApplyUpdatesView extends StatefulWidget {
  final List<DownloadInfo> download;
  final String body;
  final Future<void> Function(String url, String fileName) onStartDownload;
  final void Function() onCancelDownload;

  const ApplyUpdatesView({
    super.key,
    required this.onStartDownload,
    required this.onCancelDownload,
    required this.download, required this.body,
  });

  @override
  State<ApplyUpdatesView> createState() => _ApplyUpdatesViewState();
}

class _ApplyUpdatesViewState extends State<ApplyUpdatesView> {
  late AppInfoController appInfoController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    appInfoController = Get.find<AppInfoController>();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("有版本更新"),
      content: Obx(() {
        return
            //滚动视图
            SingleChildScrollView(
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
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (appInfoController.isDownloading.value) ...[
                // 下载进度显示
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('安装包会在GitHub仓库中下载，国内网络速度较慢，请使用代理改善网络'),
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
                          '${(appInfoController.downloadProgress.value * 100).toStringAsFixed(1)}%',
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
                      value: appInfoController.downloadProgress.value,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (appInfoController.totalBytes.value > 0)
                      Text(
                        '${FormatTimeUtil.formatBytes(appInfoController.receivedBytes.value)} / ${FormatTimeUtil.formatBytes(appInfoController.totalBytes.value)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ] else ...[
                // URL 选择界面
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.download.length > 1)
                      Text(
                        "请选择下载地址:",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (widget.download.length > 1) const SizedBox(height: 8),
                    ...List.generate(widget.download.length, (index) {
                      final data = widget.download[index];
                      final isSelected = index == _selectedIndex;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
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
                              if (widget.download.length > 1) ...[
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  )
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color:
                                        Theme.of(context).colorScheme.outline,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    FormatTimeUtil.formatBytes(data.size),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
      actions: [
        Obx(() => TextButton(
              onPressed: appInfoController.isDownloading.value
                  ? null
                  : () {
                      Get.back();
                    },
              child: const Text("稍后更新"),
            )),
        Obx(() {
          if (appInfoController.isDownloading.value) {
            // 下载中，显示取消按钮
            return TextButton(
              onPressed: () {
                widget.onCancelDownload();
              },
              child: const Text("取消下载"),
            );
          } else {
            // 未下载，显示立即更新按钮
            return TextButton(
              onPressed: () async {
                final downloadData = widget.download[_selectedIndex];
                await widget.onStartDownload(
                    downloadData.url, downloadData.fileName);
              },
              child: const Text("立即更新"),
            );
          }
        }),
      ],
    );
  }
}
