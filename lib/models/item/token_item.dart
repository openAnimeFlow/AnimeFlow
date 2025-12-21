class TokenItem {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final String? scope;
  final int userId;

  TokenItem(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,
      required this.tokenType,
      this.scope,
      required this.userId});

  factory TokenItem.fromJson(Map<String, dynamic> json) {
    return TokenItem(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
      tokenType: json['token_type'],
      scope: json['scope'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'scope': scope,
      'user_id': userId,
    };
  }

  @override
  String toString() {
    return 'TokenItem{accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType, scope: $scope, userId: $userId}';
  }
}
