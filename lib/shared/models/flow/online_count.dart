class OnlineCount {
  const OnlineCount({
    this.onlineUsers,
    this.onlineDevices,
    this.anonymousUsers,
    this.loggedInUsers,
  });

  final int? onlineUsers;
  final int? onlineDevices;
  final int? anonymousUsers;
  final int? loggedInUsers;

  factory OnlineCount.fromJson(Map<String, dynamic> json) {
    return OnlineCount(
      onlineUsers: json['onlineUsers'] as int?,
      onlineDevices: json['onlineDevices'] as int?,
      anonymousUsers: json['anonymousUsers'] as int?,
      loggedInUsers: json['loggedInUsers'] as int?,
    );
  }
}
