import 'dart:convert';

import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bangumi OAuth 令牌：写入 [FlutterSecureStorage]，
class BangumiToken implements TokenRepository {
  BangumiToken._();

  static final BangumiToken instance = BangumiToken._();

  static const _tokenKey = 'auth_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();


  @override
  Future<TokenItem?> getToken() async {
    try {
      final raw = await _storage.read(key: _tokenKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await removeToken();
        return null;
      }


      return TokenItem.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await removeToken();
      return null;
    }
  }

  @override
  Future<void> saveToken(TokenItem token) async {
    await _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
  }

  @override
  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
