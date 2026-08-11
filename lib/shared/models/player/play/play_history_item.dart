/// 云端播放记录接口返回的单条记录。
class PlayHistoryItem {
  final int id;
  final int subjectId;
  final int episodeId;
  final int episodeSort;
  final String subjectName;
  final String cover;
  final List<String> alias;
  final int positionSeconds;
  final int durationSeconds;
  final bool completed;
  final DateTime lastPlayedAt;

  const PlayHistoryItem({
    required this.id,
    required this.subjectId,
    required this.episodeId,
    required this.episodeSort,
    required this.subjectName,
    required this.cover,
    required this.alias,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.completed,
    required this.lastPlayedAt,
  });

  factory PlayHistoryItem.fromJson(Map<String, dynamic> json) {
    return PlayHistoryItem(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subjectId'] as num).toInt(),
      episodeId: (json['episodeId'] as num).toInt(),
      episodeSort: (json['episodeSort'] as num).toInt(),
      subjectName: json['subjectName'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      alias:
          (json['alias'] as List?)?.map((item) => item.toString()).toList() ??
              const [],
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
    );
  }
}
