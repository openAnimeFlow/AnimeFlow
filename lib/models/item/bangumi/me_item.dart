import 'avatar_item.dart';

class MeItem {
  final int id;
  final String username;
  final String nickname;
  final AvatarItem avatar;
  final String sign;
  final int group;
  final int joinedAt;
  final String site;
  final String location;
  final Permissions permissions;

  MeItem({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.sign,
    required this.group,
    required this.joinedAt,
    required this.site,
    required this.location,
    required this.permissions,
  });

  factory MeItem.fromJson(Map<String, dynamic> json) {
    return MeItem(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      avatar: AvatarItem.fromJson(json['avatar']),
      sign: json['sign'] ?? '',
      group: json['group'],
      joinedAt: json['joinedAt'],
      site: json['site'] ?? '',
      location: json['location'] ?? '',
      permissions: Permissions.fromJson(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar.toJson(),
      'sign': sign,
      'group': group,
      'joinedAt': joinedAt,
      'site': site,
      'location': location,
      'permissions': permissions.toJson(),
    };
  }
}

class Permissions {
  final bool subjectWikiEdit;

  Permissions({
    required this.subjectWikiEdit,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      subjectWikiEdit: json['subjectWikiEdit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectWikiEdit': subjectWikiEdit,
    };
  }
}

