import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
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
      if (mounted) {
        setState(() {
          this.playHistoryList = playHistoryList;
        });
      }
      if (mounted) {
        setState(() {
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

  /// 计算观看百分比
  /// [position] 播放进度（秒）
  /// [duration] 视频总时长（秒）
  String _calculateWatchPercentage(int position, int duration) {
    if (duration <= 0) {
      return '0%';
    }
    final percentage = (position / duration) * 100;
    if (percentage >= 100) {
      return '100%';
    }
    // 保留1位小数，如果小数部分为0则显示整数
    if (percentage % 1 == 0) {
      return '${percentage.toInt()}%';
    }
    return '${percentage.toStringAsFixed(1)}%';
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
                constraints: const BoxConstraints(maxWidth: 1400),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Row(
                        children: [
                          AnimationNetworkImage(
                              borderRadius: BorderRadius.circular(8),
                              url: playHistory.cover),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playHistory.subjectName,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Text(FormatTimeUtil.formatDateTime(
                                      playHistory.updateAt)),
                                  Text(
                                      '-观看${_calculateWatchPercentage(playHistory.position, playHistory.duration)}'),
                                ],
                              )
                            ],
                          ))
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
