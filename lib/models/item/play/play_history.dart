import 'package:hive/hive.dart';

part 'play_history.g.dart';

@HiveType(typeId: 2)
class PlayHistory extends HiveObject {
  @HiveField(0)
  int subjectId;

  @HiveField(1)
  int episodeId;

  @HiveField(2)
  int episodeSort;

  @HiveField(3)
  String subjectName;

  @HiveField(4)
  String image;

  @HiveField(5)
  DateTime playTime;

  PlayHistory({
    required this.subjectId,
    required this.episodeId,
    required this.episodeSort,
    required this.subjectName,
    required this.image,
    required this.playTime,
  });

  @override
  String toString() {
    return 'PlayHistory{subjectId: $subjectId, episodeId: $episodeId, episodeSort: $episodeSort, subjectName: $subjectName, image: $image, playTime: $playTime}';
  }
}
