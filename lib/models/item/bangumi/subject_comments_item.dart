import 'package:anime_flow/models/item/bangumi/user_comments_item.dart';

class SubjectCommentItem {
  final List<DataItem> data;
  final int total;

  SubjectCommentItem({required this.data, required this.total});

  factory SubjectCommentItem.fromJson(Map<String, dynamic> json) {
    return SubjectCommentItem(
      data: (json['data'] as List)
          .map((e) => DataItem.fromJson(e))
          .toList(),
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

// 数据项类
class DataItem {
  final int id;
  final UserCommentsItem user;
  final int type;
  final int rate;
  final String comment;
  final int updatedAt;

  DataItem({
    required this.id,
    required this.user,
    required this.type,
    required this.rate,
    required this.comment,
    required this.updatedAt,
  });

  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
      id: json['id'],
      user: UserCommentsItem.fromJson(json['user']),
      type: json['type'],
      rate: json['rate'],
      comment: json['comment'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'type': type,
      'rate': rate,
      'comment': comment,
      'updatedAt': updatedAt,
    };
  }
}