import 'dart:convert';

import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter/foundation.dart';

/// 当前登录会话的资料。
class UserProfileCache {
  static FlowUsers? read(String sessionId) {
    try {
      final raw = Storage.userDataCache.get(StorageKey.currentUserProfileKey);
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      if (entry['sessionId'] != sessionId) return null;
      return FlowUsers.fromJson(entry['data'] as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Failed to read user profile cache: $error');
      return null;
    }
  }

  static Future<void> write(String sessionId, FlowUsers user) async {
    try {
      await Storage.userDataCache.put(
          StorageKey.currentUserProfileKey,
          jsonEncode({
            'sessionId': sessionId,
            'data': user.toJson(),
          }));
    } catch (error) {
      debugPrint('Failed to write user profile cache: $error');
    }
  }

  static Future<void> clear() async {
    try {
      await Storage.userDataCache.delete(StorageKey.currentUserProfileKey);
    } catch (error) {
      debugPrint('Failed to clear user profile cache: $error');
    }
  }
}
