import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class PlayRecordView extends StatefulWidget {
  const PlayRecordView({super.key});

  @override
  State<PlayRecordView> createState() => _PlayRecordViewState();
}

class _PlayRecordViewState extends State<PlayRecordView> {
  final playHistoryStorage = Storage.playHistory;
  List<PlayHistory>? playHistoryList;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getPlayHistoryList();
    // 监听 Hive Box 变化，写入记录后自动刷新
    playHistoryStorage.listenable().addListener(_getPlayHistoryList);
  }

  @override
  void dispose() {
    playHistoryStorage.listenable().removeListener(_getPlayHistoryList);
    _scrollController.dispose();
    super.dispose();
  }

  void _getPlayHistoryList() async {
    try {
      final playHistoryList = await PlayRepository.getPlayHistoryList();
      playHistoryList.sort((a, b) => b.updateAt.compareTo(a.updateAt));
      if (mounted) {
        setState(() {
          this.playHistoryList = playHistoryList;
        });
      }
    } catch (e) {
      Logger().e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (playHistoryList == null || playHistoryList!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    } else {
      final playHistory = playHistoryList!;
      final filterHistory = playHistory.take(10).toList();
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '播放记录',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (playHistory.length > 10)
                  TextButton(
                    onPressed: () => Get.toNamed(RouteName.playRecord),
                    child: const Row(
                      children: [
                        Text(
                          '查看更多',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Icon(Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.grey)
                      ],
                    ),
                  )
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    GestureBinding.instance.pointerSignalResolver
                        .register(event, (event) {
                      final delta =
                          (event as PointerScrollEvent).scrollDelta.dy;
                      final newOffset =
                          (_scrollController.offset + delta).clamp(
                        _scrollController.position.minScrollExtent,
                        _scrollController.position.maxScrollExtent,
                      );
                      _scrollController.jumpTo(newOffset);
                    });
                  }
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: filterHistory.length,
                  itemBuilder: (context, index) {
                    final history = filterHistory[index];
                    return Container(
                      width: 300,
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: AnimationNetworkImage(
                                        alignment: Alignment.topCenter,
                                        fit: BoxFit.cover,
                                        url: history.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                            Colors.black87,
                                            Colors.transparent,
                                          ])),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '看到${history.episodeSort}话 ${Utils.calculatePercentage(history.position, history.duration)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: history.duration > 0
                                                  ? history.position /
                                                      history.duration
                                                  : 0,
                                              minHeight: 4,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.3),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history.subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
