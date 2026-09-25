class GitHubDeviceSession {
  const GitHubDeviceSession({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresAt,
    required this.intervalSeconds,
  });

  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final DateTime expiresAt;
  final int intervalSeconds;

  factory GitHubDeviceSession.fromJson(
      Map<String, dynamic> json, DateTime now) {
    final deviceCode = json['device_code'];
    final userCode = json['user_code'];
    final uri = Uri.tryParse(json['verification_uri'] as String? ?? '');
    final expiresIn = (json['expires_in'] as num?)?.toInt();
    final interval = (json['interval'] as num?)?.toInt();
    if (deviceCode is! String ||
        deviceCode.isEmpty ||
        userCode is! String ||
        userCode.isEmpty ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        uri.path != '/login/device' ||
        expiresIn == null ||
        expiresIn <= 0 ||
        interval == null ||
        interval <= 0) {
      throw const FormatException(
          'Invalid GitHub device authorization response');
    }
    return GitHubDeviceSession(
      deviceCode: deviceCode,
      userCode: userCode,
      verificationUri: uri,
      expiresAt: now.add(Duration(seconds: expiresIn)),
      intervalSeconds: interval,
    );
  }
}

class GitHubToken {
  const GitHubToken({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  final String tokenType;

  factory GitHubToken.fromExchange(Map<String, dynamic> json, DateTime now) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final accessSeconds = (json['expiresIn'] as num?)?.toInt();
    final refreshSeconds = (json['refreshTokenExpiresIn'] as num?)?.toInt();
    final type = json['tokenType'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        accessSeconds == null ||
        accessSeconds <= 0 ||
        refreshSeconds == null ||
        refreshSeconds <= 0 ||
        type is! String ||
        type.toLowerCase() != 'bearer') {
      throw const FormatException('Invalid GitHub token response');
    }
    return GitHubToken(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: now.add(Duration(seconds: accessSeconds)),
      refreshExpiresAt: now.add(Duration(seconds: refreshSeconds)),
      tokenType: type,
    );
  }

  factory GitHubToken.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final accessExpiresAt = json['accessExpiresAt'];
    final refreshExpiresAt = json['refreshExpiresAt'];
    final type = json['tokenType'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        accessExpiresAt is! int ||
        refreshExpiresAt is! int ||
        type is! String ||
        type.toLowerCase() != 'bearer') {
      throw const FormatException('Invalid saved GitHub token');
    }
    return GitHubToken(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt:
          DateTime.fromMillisecondsSinceEpoch(accessExpiresAt, isUtc: true),
      refreshExpiresAt:
          DateTime.fromMillisecondsSinceEpoch(refreshExpiresAt, isUtc: true),
      tokenType: type,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessExpiresAt': accessExpiresAt.toUtc().millisecondsSinceEpoch,
        'refreshExpiresAt': refreshExpiresAt.toUtc().millisecondsSinceEpoch,
        'tokenType': tokenType,
      };
}

class GitHubUser {
  const GitHubUser({required this.id, required this.login, this.avatarUrl});

  final int id;
  final String login;
  final String? avatarUrl;

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final login = json['login'];
    if (id is! int || login is! String || login.isEmpty) {
      throw const FormatException('Invalid GitHub user response');
    }
    return GitHubUser(
      id: id,
      login: login,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class GitHubExchangeResult {
  const GitHubExchangeResult(
      {required this.status, this.token, this.intervalSeconds});

  final String status;
  final GitHubToken? token;
  final int? intervalSeconds;

  factory GitHubExchangeResult.fromJson(
      Map<String, dynamic> json, DateTime now) {
    final status = json['status'];
    if (status is! String || status.isEmpty) {
      throw const FormatException('Invalid GitHub exchange status');
    }
    return GitHubExchangeResult(
      status: status,
      token: status == 'success' ? GitHubToken.fromExchange(json, now) : null,
      intervalSeconds: (json['interval'] as num?)?.toInt(),
    );
  }
}
