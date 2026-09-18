import 'package:anime_flow/shared/models/bangumi/image_five_item.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';

class WatchingSubject {
  const WatchingSubject({
    required this.subjectId,
    required this.name,
    required this.nameCn,
    required this.images,
    required this.online,
  });

  final int subjectId;
  final String name;
  final String nameCn;
  final ImageFiveItem? images;
  final OnlineCount online;

  factory WatchingSubject.fromJson(Map<String, dynamic> json) {
    return WatchingSubject(
      subjectId: (json['subjectId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      nameCn: json['nameCn'] as String? ?? '',
      images: json['images'] is Map
          ? ImageFiveItem.fromJson(
              Map<String, dynamic>.from(json['images'] as Map),
            )
          : null,
      online: OnlineCount.fromJson(
        Map<String, dynamic>.from(json['online'] as Map? ?? const {}),
      ),
    );
  }

  String get displayName => nameCn.isNotEmpty ? nameCn : name;
}
