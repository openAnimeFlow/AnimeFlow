import 'package:hive/hive.dart';

part 'play_history.g.dart';

@HiveType(typeId: 2)
class PlayHistory extends HiveObject {
  /// 番剧id
  @HiveField(0)
  int subjectId;

  /// 集id
  @HiveField(1)
  int episodeId;

  /// 集数
  @HiveField(2)
  int episodeSort;

  /// 名称
  @HiveField(3)
  String subjectName;

  /// 封面
  @HiveField(4)
  String cover;

  /// 更新时间
  @HiveField(5)
  DateTime updateAt;

  /// 播放进度
  @HiveField(6)
  int position;

  /// 视频总时长
  @HiveField(7)
  int duration;

  PlayHistory({
    required this.subjectId,
    required this.episodeId,
    required this.episodeSort,
    required this.subjectName,
    required this.cover,
    required this.updateAt,
    required this.position,
    required this.duration,
  });

  @override
  String toString() {
    return 'PlayHistory{subjectId: $subjectId, episodeId: $episodeId, episodeSort: $episodeSort, subjectName: $subjectName, cover: $cover, updateAt: $updateAt, position: $position, duration: $duration}';
  }
}
