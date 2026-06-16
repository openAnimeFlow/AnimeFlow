class FlowUsers {
  final int id;
  final String email;
  final String nickname;
  final String avatar;
  final String createTime;

  FlowUsers({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.createTime,
  });
  factory FlowUsers.fromJson(Map<String, dynamic> json) {
    return FlowUsers(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String,
      createTime: json['createTime'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'createTime': createTime,
    };
  }
}