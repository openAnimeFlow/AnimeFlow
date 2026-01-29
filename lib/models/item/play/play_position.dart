import 'package:hive/hive.dart';

part 'play_position.g.dart';

@HiveType(typeId: 1)
class PlayPosition extends HiveObject {
  @HiveField(0)
  String playId;

  @HiveField(1)
  int position;

  @HiveField(2)
  int duration;

  @HiveField(3)
  int updateAt;

  PlayPosition({
    required this.playId,
    required this.position,
    required this.duration,
    required this.updateAt,
  });

  @override
  String toString() {
    return 'PlayHistory{playId: $playId, position: $position, duration: $duration, updateAt: $updateAt}';
  }
}
