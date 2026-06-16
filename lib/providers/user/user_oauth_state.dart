enum OAuthPurpose {
  login,
  bindBangumi,
}

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
