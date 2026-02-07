import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class PlayRecordPage extends StatefulWidget {
  const PlayRecordPage({super.key});

  @override
  State<PlayRecordPage> createState() => _PlayRecordPageState();
}

class _PlayRecordPageState extends State<PlayRecordPage> {
  final playHistoryStorage = Storage.playHistory;
  List<PlayHistory>? playHistoryList;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getPlayHistoryList();
  }

  void _getPlayHistoryList() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final playHistoryList = await PlayRepository.getPlayHistoryList();
      playHistoryList.sort((a, b) => b.updateAt.compareTo(a.updateAt));
      if (mounted) {
        setState(() {
          this.playHistoryList = playHistoryList;
          isLoading = false;
        });
      }
    } catch (e) {
      Logger().e(e);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放记录'),
      ),
      body: Center(
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (playHistoryList == null || playHistoryList!.isEmpty) {
              return const Center(
                child: Text('暂无数据'),
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
                    final subjectBasicData = SubjectBasicData(
                        id: playHistory.subjectId,
                        name: playHistory.subjectName,
                        image: playHistory.cover);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Get.toNamed(RouteName.animeInfo,
                          arguments: subjectBasicData),
                      child: Row(
                        children: [
                          AnimationNetworkImage(
                              filterQuality: FilterQuality.high,
                              borderRadius: BorderRadius.circular(8),
                              url: playHistory.cover),
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
                                        '-观看${Utils.calculatePercentage(playHistory.position, playHistory.duration)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
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
                                            final episodeSort =
                                                playHistory.episodeSort;
                                            await Get.toNamed(RouteName.play,
                                                arguments: {
                                                  'subjectBasicData':
                                                      subjectBasicData,
                                                  'continueEpisode':
                                                      episodeSort,
                                                });
                                            // 从播放页面返回后刷新数据
                                            if (mounted) {
                                              _getPlayHistoryList();
                                            }
                                          },
                                          child: Text(
                                            '播放(${playHistory.episodeSort.toString().padLeft(2, '0')})',
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
