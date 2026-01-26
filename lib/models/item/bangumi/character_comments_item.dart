import 'package:anime_flow/models/item/bangumi/user_comments_item.dart';

/// 角色吐槽项
class CharacterCommentItem {
  final int id;
  final int mainID;
  final int creatorID;
  final int relatedID;
  final int createdAt;
  final String content;
  final int state;
  final List<CharacterCommentReply> replies;
  final UserCommentsItem user;

  CharacterCommentItem({
    required this.id,
    required this.mainID,
    required this.creatorID,
    required this.relatedID,
    required this.createdAt,
    required this.content,
    required this.state,
    required this.replies,
    required this.user,
  });

  factory CharacterCommentItem.fromJson(Map<String, dynamic> json) {
    return CharacterCommentItem(
      id: json['id'] as int,
      mainID: json['mainID'] as int,
      creatorID: json['creatorID'] as int,
      relatedID: json['relatedID'] as int,
      createdAt: json['createdAt'] as int,
      content: json['content'] as String,
      state: json['state'] as int,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((e) => CharacterCommentReply.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : <CharacterCommentReply>[],
      user: UserCommentsItem.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mainID': mainID,
      'creatorID': creatorID,
      'relatedID': relatedID,
      'createdAt': createdAt,
      'content': content,
      'state': state,
      'replies': replies.map((e) => e.toJson()).toList(),
      'user': user.toJson(),
    };
  }
}

/// 角色吐槽回复项
class CharacterCommentReply {
  final int id;
  final int mainID;
  final int creatorID;
  final int relatedID;
  final int createdAt;
  final String content;
  final int state;
  final UserCommentsItem user;

  CharacterCommentReply({
    required this.id,
    required this.mainID,
    required this.creatorID,
    required this.relatedID,
    required this.createdAt,
    required this.content,
    required this.state,
    required this.user,
  });

  factory CharacterCommentReply.fromJson(Map<String, dynamic> json) {
    return CharacterCommentReply(
      id: json['id'] as int,
      mainID: json['mainID'] as int,
      creatorID: json['creatorID'] as int,
      relatedID: json['relatedID'] as int,
      createdAt: json['createdAt'] as int,
      content: json['content'] as String,
      state: json['state'] as int,
      user: UserCommentsItem.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mainID': mainID,
      'creatorID': creatorID,
      'relatedID': relatedID,
      'createdAt': createdAt,
      'content': content,
      'state': state,
      'user': user.toJson(),
    };
  }
}

