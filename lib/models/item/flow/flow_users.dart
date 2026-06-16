import 'package:anime_flow/models/item/flow/flow_user_collection_counts.dart';

class FlowUsers {
  final int id;
  final String email;
  final String nickname;
  final String avatar;
  final String createTime;
  final FlowUserCollectionCounts collectionCounts;

  FlowUsers({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.createTime,
    FlowUserCollectionCounts? collectionCounts,
  }) : collectionCounts = collectionCounts ?? const FlowUserCollectionCounts();

  factory FlowUsers.fromJson(Map<String, dynamic> json) {
    return FlowUsers(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      createTime: json['createTime'] as String,
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
