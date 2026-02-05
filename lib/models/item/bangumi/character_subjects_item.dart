import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';

/// 角色出演作品数据类
class CharacterCastsItem {
  final List<CharacterSubjectData> data;
  final int total;

  CharacterCastsItem({
    required this.data,
    required this.total,
  });

  factory CharacterCastsItem.fromJson(Map<String, dynamic> json) {
    var dataList = <CharacterSubjectData>[];
    if (json['data'] != null) {
      dataList = (json['data'] as List)
          .map((item) => CharacterSubjectData.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return CharacterCastsItem(
      data: dataList,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

/// 角色出演作品数据项
class CharacterSubjectData {
  final Subject subject;
  final List<Actor> actors;
  final int type;

  CharacterSubjectData({
    required this.subject,
    required this.actors,
    required this.type,
  });

  factory CharacterSubjectData.fromJson(Map<String, dynamic> json) {
    return CharacterSubjectData(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      actors: json['actors'] != null
          ? (json['actors'] as List)
              .map((item) => Actor.fromJson(item as Map<String, dynamic>))
              .toList()
          : <Actor>[],
      type: json['type'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'actors': actors.map((e) => e.toJson()).toList(),
      'type': type,
    };
  }
}