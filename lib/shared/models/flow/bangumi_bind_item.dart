class BangumiBindItem {
  final bool bound;
  final int? platformUid;
  final String? username;
  final String? nickname;
  final String? avatar;

  const BangumiBindItem({
    required this.bound,
    this.platformUid,
    this.username,
    this.nickname,
    this.avatar,
  });

  factory BangumiBindItem.fromJson(Map<String, dynamic> json) {
    return BangumiBindItem(
      bound: json['bound'] as bool? ?? false,
      platformUid: json['platformUid'] as int?,
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}
