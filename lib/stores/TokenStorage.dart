import 'dart:convert';

import 'package:anime_flow/models/item/token_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();

  Future<void> saveToken(TokenItem token) async {
    await _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
  }

  Future<TokenItem?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null ? TokenItem.fromJson(jsonDecode(token)) : null;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

final tokenStorage = TokenStorage();
