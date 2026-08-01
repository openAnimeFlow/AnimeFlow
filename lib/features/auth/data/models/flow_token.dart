class FlowToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int refreshExpiresIn;
  final String sessionId;

  FlowToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.sessionId,
  });

  factory FlowToken.fromJson(Map<String, dynamic> json) {
    return FlowToken(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num).toInt(),
      refreshExpiresIn: (json['refreshExpiresIn'] as num).toInt(),
      sessionId: json['sessionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'refreshExpiresIn': refreshExpiresIn,
      'sessionId': sessionId,
    };
  }
}
