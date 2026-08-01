import 'package:anime_flow/shared/models/bangumi/user_comments_item.dart';

class EpisodeComment {
  final int id;
  final int mainID;
  final int creatorID;
  final int relatedID;
  final int createdAt;
  final String content;
  final int state;
  final List<Reply> replies;
  final UserCommentsItem user;
  final List<Reaction>? reactions;

  EpisodeComment({
    required this.id,
    required this.mainID,
    required this.creatorID,
    required this.relatedID,
    required this.createdAt,
    required this.content,
    required this.state,
    required this.replies,
    required this.user,
    this.reactions,
  });

  factory EpisodeComment.fromJson(Map<String, dynamic> json) {
    return EpisodeComment(
      id: json['id'] as int,
      mainID: json['mainID'] as int,
      creatorID: json['creatorID'] as int,
      relatedID: json['relatedID'] as int,
      createdAt: json['createdAt'] as int,
      content: json['content'] as String,
      state: json['state'] as int,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Reply.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      user: UserCommentsItem.fromJson(json['user'] as Map<String, dynamic>),
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      if (reactions != null)
        'reactions': reactions!.map((e) => e.toJson()).toList(),
      'user': user.toJson(),
    };
  }
}

class Reply {
  final int id;
  final int mainID;
  final int creatorID;
  final int relatedID;
  final int createdAt;
  final String content;
  final int state;
  final UserCommentsItem user;

  Reply({
    required this.id,
    required this.mainID,
    required this.creatorID,
    required this.relatedID,
    required this.createdAt,
    required this.content,
    required this.state,
    required this.user,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
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

class Reaction {
  final List<ReactionUser> users;
  final int value;

  Reaction({
    required this.users,
    required this.value,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      users: (json['users'] as List<dynamic>)
          .map((e) => ReactionUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((e) => e.toJson()).toList(),
      'value': value,
    };
  }
}

class ReactionUser {
  final int id;
  final String username;
  final String nickname;

  ReactionUser({
    required this.id,
    required this.username,
    required this.nickname,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
    };
  }
}
