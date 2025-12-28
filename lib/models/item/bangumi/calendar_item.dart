import 'package:anime_flow/models/item/bangumi/subject_item.dart';

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

  CalendarItem({required this.subject, required this.watchers});

  factory CalendarItem.fromJson(Map<String, dynamic> json) {
    return CalendarItem(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      watchers: json['watchers'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'watchers': watchers,
    };
  }
}
//
// class Subject {
//   final int id;
//   final String name;
//   final String nameCN;
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
//       rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
//       locked: json['locked'] as bool,
//       nsfw: json['nsfw'] as bool,
//       images: Images.fromJson(json['images'] as Map<String, dynamic>),
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
//       count: (json['count'] as List).map((e) => e as int).toList(),
//       score: (json['score'] is int)
//           ? (json['score'] as int).toDouble()
//           : json['score'] as double,
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
