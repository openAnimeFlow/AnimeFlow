import 'dart:convert';

import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AnimeFlow 账号令牌：写入 [FlutterSecureStorage]。
class FlowTokenStorage implements TokenRepository<FlowToken> {
  FlowTokenStorage._();

  static final FlowTokenStorage instance = FlowTokenStorage._();

  static const _tokenKey = 'flow_auth_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<FlowToken?> getToken() async {
    try {
      final raw = await _storage.read(key: _tokenKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await removeToken();
        return null;
      }

      return FlowToken.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
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
