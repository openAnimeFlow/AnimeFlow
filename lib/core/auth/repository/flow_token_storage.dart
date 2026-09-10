import 'dart:convert';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AnimeFlow 账号令牌：写入 [FlutterSecureStorage]。
class FlowTokenStorage implements TokenRepository<FlowToken> {
  FlowTokenStorage._();

  static final FlowTokenStorage instance = FlowTokenStorage._();

  static const _tokenKey = 'flow_auth_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<FlowToken?> getToken() async {
    // Storage failures must propagate without deleting valid credentials.
    final raw = await _storage.read(key: _tokenKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await removeToken();
        return null;
      }

      return FlowToken.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await removeToken();
      return null;
    } on TypeError {
      await removeToken();
      return null;
    }
  }

  @override
  Future<void> saveToken(FlowToken token) async {
    await _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
  }

  @override
  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
