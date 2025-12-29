import 'package:anime_flow/models/item/bangumi/subject_item.dart';

/// Data class for hot items
class HotItem {
  final List<Data> data;
  final int total;

  HotItem({
    required this.data,
    required this.total,
  });

  factory HotItem.fromJson(Map<String, dynamic> json) {
    var dataList = <Data>[];
    if (json['data'] != null) {
      dataList = (json['data'] as List)
          .map((item) => Data.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return HotItem(
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

/// Data class for individual item
class Data {
  final Subject subject;
  final int count;

  Data({
    required this.subject,
    required this.count,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'count': count,
    };
  }
}