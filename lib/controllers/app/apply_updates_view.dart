import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApplyUpdatesView extends StatefulWidget {
  final List<String> urlList;
  final String versionMessage;
  final Future<void> Function(String) onStartDownload;
  final void Function() onCancelDownload;

  const ApplyUpdatesView({
    super.key,
    required this.urlList,
    required this.versionMessage,
    required this.onStartDownload,
    required this.onCancelDownload,
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
      title: const Text("检查更新"),
      content: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.versionMessage),
            const SizedBox(height: 5),
            if (appInfoController.isDownloading.value) ...[
              // 下载进度显示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('安装包会在GitHub仓库中下载，国内网络速度较慢，请使用代理改善网络'),
                  ),
                  const Divider(),
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
                      '${appInfoController.formatBytes(appInfoController.receivedBytes.value)} / ${appInfoController.formatBytes(appInfoController.totalBytes.value)}',
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
                  if (widget.urlList.length > 1)
                    Text(
                      "请选择下载地址:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (widget.urlList.length > 1) const SizedBox(height: 8),
                  ...List.generate(widget.urlList.length, (index) {
                    final url = widget.urlList[index];
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
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.radio_button_unchecked,
                                color: Theme.of(context).colorScheme.outline,
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                url,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
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
                final downloadUrl = widget.urlList[_selectedIndex];
                await widget.onStartDownload(downloadUrl);
              },
              child: const Text("立即更新"),
            );
          }
        }),
      ],
    );
  }
}
