import 'package:anime_flow/shared/models/bangumi/subject_item.dart';

class Calendar {
  final Map<String, List<CalendarItem>> calendarData;

  Calendar({required this.calendarData});

  factory Calendar.fromJson(Map<String, dynamic> json) {
    final calendarData = <String, List<CalendarItem>>{};

    for (int i = 1; i <= 7; i++) {
      final key = i.toString();
      if (json.containsKey(key) && json[key] is List) {
        calendarData[key] = (json[key] as List)
            .map((item) => CalendarItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return Calendar(calendarData: calendarData);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    calendarData.forEach((key, value) {
      data[key] = value.map((item) => item.toJson()).toList();
    });
    return data;
  }
}

class CalendarItem {
  final Subject subject;
  final int watchers;
  final EpisodeInfo? latestEpisode;
  final EpisodeInfo? nextEpisode;
  final int episodeCount;

  CalendarItem({
    required this.subject,
    required this.watchers,
    this.latestEpisode,
    this.nextEpisode,
    this.episodeCount = 0,
  });

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      watchers: (json['watchers'] as num?)?.toInt() ?? 0,
      latestEpisode: json['latestEpisode'] is Map
          ? EpisodeInfo.fromJson(
              Map<String, dynamic>.from(json['latestEpisode'] as Map),
            )
          : null,
      nextEpisode: json['nextEpisode'] is Map
          ? EpisodeInfo.fromJson(
              Map<String, dynamic>.from(json['nextEpisode'] as Map),
            )
          : null,
      episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'watchers': watchers,
      'latestEpisode': latestEpisode?.toJson(),
      'nextEpisode': nextEpisode?.toJson(),
      'episodeCount': episodeCount,
    };
  }
}

class EpisodeInfo {
  final int id;
  final int sort;
  final String name;
  final String nameCn;
  final String airdate;
  final String duration;

  EpisodeInfo({
    required this.id,
    required this.sort,
    required this.name,
    required this.nameCn,
    required this.airdate,
    required this.duration,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sort: (json['sort'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      nameCn: json['nameCn'] as String? ?? '',
      airdate: json['airdate'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sort': sort,
      'name': name,
      'nameCn': nameCn,
      'airdate': airdate,
      'duration': duration,
    };
  }
}
