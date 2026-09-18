class OnlineCount {
  const OnlineCount({
    required this.onlineUsers,
    required this.onlineDevices,
    required this.anonymousUsers,
    required this.loggedInUsers,
  });

  final int onlineUsers;
  final int onlineDevices;
  final int anonymousUsers;
  final int loggedInUsers;

  factory OnlineCount.fromJson(Map<String, dynamic> json) {
    return OnlineCount(
      onlineUsers: (json['onlineUsers'] as num?)?.toInt() ?? 0,
      onlineDevices: (json['onlineDevices'] as num?)?.toInt() ?? 0,
      anonymousUsers: (json['anonymousUsers'] as num?)?.toInt() ?? 0,
      loggedInUsers: (json['loggedInUsers'] as num?)?.toInt() ?? 0,
    );
  }
}
