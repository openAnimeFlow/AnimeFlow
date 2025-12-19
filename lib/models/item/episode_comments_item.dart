class EpisodeComment {
  final int id;
  final int mainID;
  final int creatorID;
  final int relatedID;
  final int createdAt;
  final String content;
  final int state;
  final List<Reply> replies;
  final User user;
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
          .toList() ?? [],
      user: User.fromJson(json['user'] as Map<String, dynamic>),
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
      if (reactions != null) 'reactions': reactions!.map((e) => e.toJson()).toList(),
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
  final User user;

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
      user: User.fromJson(json['user'] as Map<String, dynamic>),
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

class User {
  final int id;
  final String username;
  final String nickname;
  final Avatar avatar;
  final int group;
  final String sign;
  final int joinedAt;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.group,
    required this.sign,
    required this.joinedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      group: json['group'] as int,
      sign: json['sign'] as String,
      joinedAt: json['joinedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar.toJson(),
      'group': group,
      'sign': sign,
      'joinedAt': joinedAt,
    };
  }
}

class Avatar {
  final String small;
  final String medium;
  final String large;

  Avatar({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      small: json['small'] as String,
      medium: json['medium'] as String,
      large: json['large'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'small': small,
      'medium': medium,
      'large': large,
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
