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
  final User user;
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
      user: User.fromJson(json['user']),
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

// 用户信息类
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
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      avatar: Avatar.fromJson(json['avatar']),
      group: json['group'],
      sign: json['sign'] ?? '',
      joinedAt: json['joinedAt'],
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

// 头像信息类
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
      small: json['small'],
      medium: json['medium'],
      large: json['large'],
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
