import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/data/repository/user_profile_cache.dart';
import 'package:anime_flow/features/user/data/repository/user_repository.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'collection_refresh_provider.dart';

part 'user_state_provider.g.dart';

@Riverpod(keepAlive: true)
Future<BangumiBindItem?> bangumiBind(Ref ref) async {
  ref.watch(bangumiBindingRevisionProvider);
  final token = await ref.watch(currentFlowTokenProvider.future);
  if (token == null) {
    return null;
  }

  try {
    return await FlowApi.getBangumiBindService();
  } catch (error, stackTrace) {
    final latestToken = await ref.read(flowTokenRepositoryProvider).getToken();
    if (latestToken == null) {
      return null;
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

@Riverpod(keepAlive: true)
class CurrentUserInfo extends _$CurrentUserInfo {
  bool _currentSession(int revision) =>
      ref.mounted && ref.read(authSessionRevisionProvider) == revision;

  FlowToken? _flowToken;
  int _revision = 0;

  /// 请求完成时同时检查 provider 生命周期及登录会话。
  Future<bool> _isCurrent(FlowToken token, int revision) async {
    if (!ref.mounted || revision != _revision) return false;
    final latest = await ref.read(flowTokenRepositoryProvider).getToken();
    return ref.mounted &&
        revision == _revision &&
        latest?.sessionId == token.sessionId;
  }

  Future<void> _applyUser(
      FlowUsers user, FlowToken? token, int revision) async {
    if (token == null) return;
    try {
      if (!await _isCurrent(token, revision)) return;
    } catch (error) {
      debugPrint('Failed to verify user profile session: $error');
      return;
    }
    state = AsyncData(user);
    await UserProfileCache.write(token.sessionId, user);
  }

  void moveCollectionCount(int oldType, int newType) {
    final user = state.asData?.value;
    if (user == null || oldType == newType) return;
    final counts = user.collectionCounts;
    int updatedCount(int type) {
      return (counts.countForType(type) +
              (type == newType ? 1 : 0) -
              (type == oldType ? 1 : 0))
          .clamp(0, 1 << 31);
    }

    final updatedUser = user.copyWith(
      collectionCounts: counts.copyWith(
        planToWatch: updatedCount(1),
        watched: updatedCount(2),
        watching: updatedCount(3),
        onHold: updatedCount(4),
        abandoned: updatedCount(5),
      ),
    );
    state = AsyncData(updatedUser);
    final revision = ++_revision;
    unawaited(_applyUser(updatedUser, _flowToken, revision));
  }

  @override
  Future<FlowUsers?> build() async {
    ref.watch(collectionRefreshProvider);
    ref.watch(authSessionRevisionProvider);
    final revision = ++_revision;
    _flowToken = null;
    ref.onDispose(() => _revision++);
    final userRepository = ref.watch(userRepositoryProvider);
    final flowToken = await ref.watch(currentFlowTokenProvider.future);
    if (!ref.mounted || revision != _revision) return null;
    if (flowToken == null) {
      await UserProfileCache.clear();
      return null;
    }
    _flowToken = flowToken;

    final cached = UserProfileCache.read(flowToken.sessionId);
    if (cached != null) {
      // 下一轮事件再刷新，确保缓存先进入 AsyncData，快速响应也不会被旧值覆盖。
      unawaited(Future<void>(() async {
        if (!ref.mounted || revision != _revision) return;
        try {
          final user = await userRepository.getCurrentUserProfile(flowToken);
          await _applyUser(user, flowToken, revision);
        } catch (error) {
          if (!ref.mounted || revision != _revision) return;
          try {
            final latest =
                await ref.read(flowTokenRepositoryProvider).getToken();
            if (!ref.mounted || revision != _revision) return;
            if (latest == null) {
              state = const AsyncData(null);
              await UserProfileCache.clear();
            }
          } catch (_) {
            // 读取凭据失败不应删除有效缓存。
          }
          debugPrint('Failed to refresh user profile: $error');
        }
      }));
      return cached;
    }

    try {
      final user = await userRepository.getCurrentUserProfile(flowToken);
      if (!await _isCurrent(flowToken, revision)) return null;
      await UserProfileCache.write(flowToken.sessionId, user);
      return user;
    } catch (error, stackTrace) {
      if (!ref.mounted || revision != _revision) return null;
      final latestToken =
          await ref.read(flowTokenRepositoryProvider).getToken();
      if (latestToken == null) {
        return null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String?> uploadAvatar(Uint8List imageBytes) async {
    final sessionRevision = ref.read(authSessionRevisionProvider);
    final token = _flowToken;
    final revision = ++_revision;
    try {
      final updatedUser =
          await ref.read(userRepositoryProvider).uploadAvatar(imageBytes);
      if (!_currentSession(sessionRevision)) return '用户会话已变更';
      await _applyUser(updatedUser, token, revision);
      return null;
    } on AnimeFlowApiException catch (e) {
      return e.message;
    } catch (_) {
      return '上传头像失败';
    }
  }

  /// 更新昵称。
  ///
  /// 返回 `null` 表示成功，否则返回错误描述字符串。
  Future<String?> updateNickname(String newNickname) async {
    final sessionRevision = ref.read(authSessionRevisionProvider);
    final token = _flowToken;
    final revision = ++_revision;
    try {
      final updatedUser =
          await ref.read(userRepositoryProvider).updateNickname(newNickname);
      if (!_currentSession(sessionRevision)) return '用户会话已变更';
      await _applyUser(updatedUser, token, revision);
      return null;
    } on AnimeFlowApiException catch (e) {
      return e.message;
    } catch (_) {
      return '更新昵称失败';
    }
  }

  /// 更新背景图。
  ///
  /// 传入背景图的 ID（[BackgroundImageItem.id]），传入 `null` 清除背景。
  /// 返回 `null` 表示成功，否则返回错误描述字符串。
  Future<String?> updateBackground(int? backgroundId) async {
    final sessionRevision = ref.read(authSessionRevisionProvider);
    final token = _flowToken;
    final revision = ++_revision;
    try {
      final updatedUser =
          await ref.read(userRepositoryProvider).updateBackground(backgroundId);
      if (!_currentSession(sessionRevision)) return '用户会话已变更';
      await _applyUser(updatedUser, token, revision);
      return null;
    } on AnimeFlowApiException catch (e) {
      return e.message;
    } catch (_) {
      return '更新背景图失败';
    }
  }
}
