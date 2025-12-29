import 'package:anime_flow/models/item/bangumi/subject_item.dart';

class SubjectRelationItem {
  final List<SubjectRelationData> data;
  final int total;

  SubjectRelationItem({
    required this.data,
    required this.total,
  });

  factory SubjectRelationItem.fromJson(Map<String, dynamic> json) {
    return SubjectRelationItem(
      data: (json['data'] as List).map((item) => SubjectRelationData.fromJson(item)).toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }
}

class SubjectRelationData {
  final Subject subject;
  final Relation relation;
  final int order;

  SubjectRelationData({
    required this.subject,
    required this.relation,
    required this.order,
  });

  factory SubjectRelationData.fromJson(Map<String, dynamic> json) {
    return SubjectRelationData(
      subject: Subject.fromJson(json['subject']),
      relation: Relation.fromJson(json['relation']),
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'relation': relation.toJson(),
      'order': order,
    };
  }
}
//
// class Subject {
//   final int id;
//   final String name;
//   final String? nameCN;
//   final int type;
//   final String info;
//   final Rating rating;
//   final bool locked;
//   final bool nsfw;
//   final Images images;
//
//   Subject({
//     required this.id,
//     required this.name,
//     required this.nameCN,
//     required this.type,
//     required this.info,
//     required this.rating,
//     required this.locked,
//     required this.nsfw,
//     required this.images,
//   });
//
//   factory Subject.fromJson(Map<String, dynamic> json) {
//     return Subject(
//       id: json['id'] as int,
//       name: json['name'] as String,
//       nameCN: json['nameCN'] as String,
//       type: json['type'] as int,
//       info: json['info'] as String,
//       rating: Rating.fromJson(json['rating']),
//       locked: json['locked'] as bool,
//       nsfw: json['nsfw'] as bool,
//       images: Images.fromJson(json['images']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'nameCN': nameCN,
//       'type': type,
//       'info': info,
//       'rating': rating.toJson(),
//       'locked': locked,
//       'nsfw': nsfw,
//       'images': images.toJson(),
//     };
//   }
// }
//
// class Rating {
//   final int rank;
//   final List<int> count;
//   final double score;
//   final int total;
//
//   Rating({
//     required this.rank,
//     required this.count,
//     required this.score,
//     required this.total,
//   });
//
//   factory Rating.fromJson(Map<String, dynamic> json) {
//     return Rating(
//       rank: json['rank'] as int,
//       count: (json['count'] as List).map((item) => item as int).toList(),
//       score: (json['score'] as num).toDouble(),
//       total: json['total'] as int,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'rank': rank,
//       'count': count,
//       'score': score,
//       'total': total,
//     };
//   }
// }
//
// class Images {
//   final String large;
//   final String common;
//   final String medium;
//   final String small;
//   final String grid;
//
//   Images({
//     required this.large,
//     required this.common,
//     required this.medium,
//     required this.small,
//     required this.grid,
//   });
//
//   factory Images.fromJson(Map<String, dynamic> json) {
//     return Images(
//       large: json['large'] as String,
//       common: json['common'] as String,
//       medium: json['medium'] as String,
//       small: json['small'] as String,
//       grid: json['grid'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'large': large,
//       'common': common,
//       'medium': medium,
//       'small': small,
//       'grid': grid,
//     };
//   }
// }

class Relation {
  final int id;
  final String en;
  final String cn;
  final String jp;
  final String desc;

  Relation({
    required this.id,
    required this.en,
    required this.cn,
    required this.jp,
    required this.desc,
  });

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      id: json['id'] as int,
      en: json['en'] as String,
      cn: json['cn'] as String,
      jp: json['jp'] as String,
      desc: json['desc'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'en': en,
      'cn': cn,
      'jp': jp,
      'desc': desc,
    };
  }
}
