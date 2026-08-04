import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class PlayRecordPage extends StatefulWidget {
  const PlayRecordPage({super.key});

  @override
  State<PlayRecordPage> createState() => _PlayRecordPageState();
}

class _PlayRecordPageState extends State<PlayRecordPage> {
  late final ValueListenable<Box<PlayHistory>> _playHistoryListenable;
  List<PlayHistory>? playHistoryList;
  bool isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _playHistoryListenable = PlayHistoryService.listenable();
    _playHistoryListenable.addListener(_getPlayHistoryList);
    _getPlayHistoryList();
  }

  @override
  void dispose() {
    _playHistoryListenable.removeListener(_getPlayHistoryList);
    super.dispose();
  }

  void _getPlayHistoryList() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final playHistoryList = await PlayHistoryService.getAll();
      playHistoryList.sort((a, b) => b.updateAt.compareTo(a.updateAt));
      if (mounted) {
        setState(() {
          this.playHistoryList = playHistoryList;
          isLoading = false;
        });
      }
    } catch (e) {
      LiggLogger().e(e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const minItemWidth = 320.0;
    if (width < 450) return 1;
    return (width / minItemWidth).floor().clamp(1, 4);
  }

  Future<void> _syncPendingRecords() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await PlayHistoryService.syncPending();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      final message = result.requiresLogin
          ? l10n.loginToManageAccount
          : result.failed > 0
              ? l10n.syncStatusFailed
              : result.total == 0
                  ? l10n.syncStatusSuccess
                  : l10n.syncedItems(result.synced);
      NotificationToast.show('提示', message);
    } catch (e) {
      LiggLogger().e('手动同步播放记录失败: $e');
      if (mounted) {
        NotificationToast.show('提示', AppLocalizations.of(context).syncStatusFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _confirmAndSyncPendingRecords() async {
    if (_isSyncing) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirm),
        content: const Text('是否将未同步的播放记录同步到服务器？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _syncPendingRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.playbackHistory),
        actions: [
          IconButton(
            tooltip: _isSyncing ? l10n.syncInProgress : l10n.syncStatusIdle,
            onPressed: _isSyncing ? null : _confirmAndSyncPendingRecords,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
          ),
        ],
      ),
      body: Center(
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (playHistoryList == null || playHistoryList!.isEmpty) {
              return Center(
                child: Text(l10n.noData),
              );
            } else {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1800),
                child: GridView.builder(
                  padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: playHistoryList!.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final playHistory = playHistoryList![index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => AnimeInfoRoute.fromExtra(InfoRouteExtra(
                              id: playHistory.subjectId,
                              name: playHistory.subjectName,
                              image: playHistory.cover))
                          .push(context),
                      child: Row(
                        children: [
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: AnimationNetworkImage(
                              filterQuality: FilterQuality.high,
                              borderRadius: BorderRadius.circular(8),
                              fit: BoxFit.cover,
                              url: playHistory.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playHistory.subjectName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                          FormatTimeUtil.formatDateTime(
                                              playHistory.updateAt),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        l10n.watchedLabel(
                                          Utils.calculatePercentage(
                                            playHistory.position,
                                            playHistory.duration,
                                          ),
                                        ),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        playHistory.isSyncedToServer
                                            ? Icons.cloud_done_outlined
                                            : Icons.cloud_upload_outlined,
                                        size: 16,
                                        color: playHistory.isSyncedToServer
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        playHistory.isSyncedToServer
                                            ? l10n.syncStatusSuccess
                                            : l10n.syncStatusIdle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: playHistory.isSyncedToServer
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                      child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Spacer(),
                                      ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              elevation: 0),
                                          onPressed: () async {
                                            await PlayRoute.fromExtra(
                                                    PlayRouteExtra(
                                                        playExtra: PlayExtra(
                                                          subjectId: playHistory
                                                              .subjectId,
                                                          subjectName:
                                                              playHistory
                                                                  .subjectName,
                                                          subjectCover:
                                                              playHistory.cover,
                                                          subjectAliases:
                                                              playHistory.alias,
                                                        ),
                                                        continueEpisodeId:
                                                            playHistory
                                                                .episodeId))
                                                .push(context);
                                          },
                                          child: Text(
                                            l10n.playEpisode(
                                              playHistory.episodeSort
                                                  .toString()
                                                  .padLeft(2, '0'),
                                            ),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ))
                                    ],
                                  ))
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
