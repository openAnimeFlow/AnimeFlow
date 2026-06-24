import 'package:anime_flow/models/item/flow/flow_user_collection_counts.dart';

class FlowUsers {
  final int id;
  final String email;
  final String nickname;
  final String avatar;
  final String background;
  final int createTime;
  final FlowUserCollectionCounts collectionCounts;

  FlowUsers({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.createTime,
    required this.background,
    FlowUserCollectionCounts? collectionCounts,
  }) : collectionCounts = collectionCounts ?? const FlowUserCollectionCounts();

  factory FlowUsers.fromJson(Map<String, dynamic> json) {
    return FlowUsers(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      background: json['background'] as String,
      createTime: json['createTime'] as int,
      collectionCounts: FlowUserCollectionCounts.fromJson(
        json['collectionCounts'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'background': background,
      'createTime': createTime,
      'collectionCounts': {
        'planToWatch': collectionCounts.planToWatch,
        'watched': collectionCounts.watched,
        'watching': collectionCounts.watching,
        'onHold': collectionCounts.onHold,
        'abandoned': collectionCounts.abandoned,
      },
    };
  }
}
