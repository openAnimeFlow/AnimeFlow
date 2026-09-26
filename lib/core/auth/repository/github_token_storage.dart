import 'dart:convert';

import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GitHubTokenStorage implements TokenRepository<GitHubToken> {
  GitHubTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static final GitHubTokenStorage instance = GitHubTokenStorage();
  static const _tokenKey = 'github_auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<GitHubToken?> getToken() async {
    final raw = await _storage.read(key: _tokenKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map)
        throw const FormatException('Invalid saved GitHub token');
      return GitHubToken.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await removeToken();
      return null;
    } on TypeError {
      await removeToken();
      return null;
    }
  }

  @override
  Future<void> saveToken(GitHubToken token) =>
      _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));

  @override
  Future<void> removeToken() => _storage.delete(key: _tokenKey);
}
