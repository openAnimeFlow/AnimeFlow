enum OAuthPurpose {
  login,
  bindBangumi,
}

class OAuthHandleResult {
  const OAuthHandleResult({
    required this.success,
    required this.purpose,
    this.errorMessage,
  });

  final bool success;
  final OAuthPurpose purpose;
  final String? errorMessage;
}

/// 移动端 OAuth 回调 URI 中标识「绑定 Bangumi」的 purpose 参数值。
const String oauthBindPurposeQueryValue = 'bind';

class UserOAuthState {
  final bool isAuthorizing;
  final OAuthPurpose? purpose;

  const UserOAuthState({
    this.isAuthorizing = false,
    this.purpose,
  });

  UserOAuthState copyWith({
    bool? isAuthorizing,
    OAuthPurpose? purpose,
    bool clearPurpose = false,
  }) {
    return UserOAuthState(
      isAuthorizing: isAuthorizing ?? this.isAuthorizing,
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
    );
  }
}
