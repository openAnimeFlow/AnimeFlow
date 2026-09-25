import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/features/github/data/github_auth_api.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';

class GitHubReauthorizationRequired implements Exception {
  const GitHubReauthorizationRequired();
}

/// 串行刷新 GitHub 用户令牌，并阻止退出后的旧请求重新写入安全存储。
class GitHubTokenManager {
  GitHubTokenManager(this._repository, this._api, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static const refreshBeforeExpiry = Duration(minutes: 5);

  final TokenRepository<GitHubToken> _repository;
  final GitHubAuthApi _api;
  final DateTime Function() _now;

  Future<GitHubToken>? _refreshInFlight;
  int _generation = 0;

  Future<GitHubToken> refreshIfNeeded({bool force = false}) async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final generation = _generation;
    final token = await _repository.getToken();
    if (generation != _generation || token == null) {
      throw const GitHubReauthorizationRequired();
    }

    final otherRefresh = _refreshInFlight;
    if (otherRefresh != null) return otherRefresh;

    if (!token.refreshExpiresAt.isAfter(_now())) {
      await _clearCurrent(token, generation);
      throw const GitHubReauthorizationRequired();
    }
    if (!force &&
        token.accessExpiresAt.isAfter(_now().add(refreshBeforeExpiry))) {
      return token;
    }

    final refresh = _refresh(token, generation);
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<GitHubToken> _refresh(GitHubToken previous, int generation) async {
    late final GitHubToken rotated;
    try {
      rotated = await _api.refreshToken(previous.refreshToken);
    } on GitHubRefreshInvalidException {
      await _clearCurrent(previous, generation);
      throw const GitHubReauthorizationRequired();
    }

    if (generation != _generation) {
      throw const GitHubReauthorizationRequired();
    }
    final current = await _repository.getToken();
    if (generation != _generation || current == null) {
      throw const GitHubReauthorizationRequired();
    }
    if (current.refreshToken != previous.refreshToken) {
      return current;
    }
    await _repository.saveToken(rotated);
    if (generation != _generation) {
      await _clearCurrent(rotated, _generation);
      throw const GitHubReauthorizationRequired();
    }
    return rotated;
  }

  Future<void> _clearCurrent(GitHubToken token, int generation) async {
    if (generation != _generation) return;
    final current = await _repository.getToken();
    if (generation == _generation &&
        current?.refreshToken == token.refreshToken) {
      _generation++;
      await _repository.removeToken();
    }
  }

  Future<void> clear() async {
    _generation++;
    final pending = _refreshInFlight;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // 清理仍需在刷新失败后继续。
      }
    }
    await _repository.removeToken();
  }
}
