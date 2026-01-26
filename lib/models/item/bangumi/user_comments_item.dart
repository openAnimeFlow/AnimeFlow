import 'package:anime_flow/models/item/bangumi/avatar_item.dart';

class UserCommentsItem {
  final int id;
  final String username;
  final String nickname;
  final AvatarItem avatar;
  final int group;
  final String sign;
  final int joinedAt;

  UserCommentsItem({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.group,
    required this.sign,
    required this.joinedAt,
  });

  factory UserCommentsItem.fromJson(Map<String, dynamic> json) {
    return UserCommentsItem(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatar: AvatarItem.fromJson(json['avatar'] as Map<String, dynamic>),
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