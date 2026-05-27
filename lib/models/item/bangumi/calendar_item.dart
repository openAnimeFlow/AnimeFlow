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