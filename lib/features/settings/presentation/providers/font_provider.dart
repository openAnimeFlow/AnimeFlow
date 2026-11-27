import 'dart:io';

import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/network/api/github_api.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/shared/models/font_item.dart';
import 'package:anime_flow/app/theme/theme_provider.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_provider.g.dart';

// ──────────────────────────────────────────
// 下载状态
// ──────────────────────────────────────────
enum FontDownloadStatus { idle, downloading, done, error }

class FontDownloadState {
  const FontDownloadState({
    this.status = FontDownloadStatus.idle,
    this.progress = 0.0,
    this.filePath,
    this.errorMessage,
  });

  final FontDownloadStatus status;

  /// 0.0 ~ 1.0
  final double progress;
  final String? filePath;
  final String? errorMessage;

  FontDownloadState copyWith({
    FontDownloadStatus? status,
    double? progress,
    String? filePath,
    String? errorMessage,
  }) {
    return FontDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ──────────────────────────────────────────
// 字体列表 provider
// ──────────────────────────────────────────

@riverpod
class Font extends _$Font {
  @override
  Future<List<FontItem>> build() async {
    final mirror = AppSettings.fontRepoMirror;
    ref.watch(fontNetworkTasksProvider);
    final tasks = ref.read(fontNetworkTasksProvider.notifier);
    final cancelToken = CancelToken();
    const taskKey = 'list';
    tasks.register(taskKey, cancelToken);
    ref.onDispose(() {
      cancelToken.cancel();
      tasks.unregister(taskKey, cancelToken);
    });

    try {
      final list = await getFontList(
        mirror: mirror,
        cancelToken: cancelToken,
      );
      // 远程列表拿到后，顺手为已下载但缺少元数据的旧版本数据回填元信息，
      // 以便后续即使远程下架也能在本地正常展示并删除。
      if (!cancelToken.isCancelled) {
        Future.microtask(() async {
          try {
            if (cancelToken.isCancelled ||
                AppSettings.fontRepoMirror != mirror) {
              return;
            }
            await ref
                .read(downloadedFontMetasProvider.notifier)
                .backfillFromRemote(list);
          } catch (_) {}
        });
      }
      return list;
    } finally {
      tasks.unregister(taskKey, cancelToken);
    }
  }

  Future<List<FontItem>> getFontList({
    required RulesMirror mirror,
    CancelToken? cancelToken,
  }) async {
    return GithubApi.getRepoFonts(
      mirror: mirror,
      cancelToken: cancelToken,
    );
  }

  /// 加载字节用于字体预览
  Future<List<int>> loadingFont(
    String fontUrl, {
    required RulesMirror mirror,
    CancelToken? cancelToken,
  }) async {
    return GithubApi.previewFont(
      fontUrl,
      mirror: mirror,
      cancelToken: cancelToken,
    );
  }
}

typedef FontPreviewRequest = ({
  String fontId,
  String source,
  RulesMirror? mirror,
});

final fontPreviewProvider =
    FutureProvider.autoDispose.family<String, FontPreviewRequest>(
  (ref, request) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final mirror = request.mirror;
    final tasks =
        mirror == null ? null : ref.read(fontNetworkTasksProvider.notifier);
    final taskKey = 'preview:${request.fontId}';
    tasks?.register(taskKey, token);

    try {
      final bytes = mirror != null
          ? await ref.read(fontProvider.notifier).loadingFont(
                request.source,
                mirror: mirror,
                cancelToken: token,
              )
          : await File(request.source).readAsBytes();
      if (token.isCancelled) throw token.cancelError!;
      if (bytes.isEmpty) throw StateError('字体预览数据为空');

      final family = 'AnimeFlowPreview_${request.fontId}_${++_previewSerial}';
      final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(data)));
      await loader.load();
      return family;
    } finally {
      tasks?.unregister(taskKey, token);
    }
  },
  retry: (attempt, error) => null,
);

int _previewSerial = 0;

// ──────────────────────────────────────────
// 字体页网络任务（下载 / 预览），退出页面时统一取消
// ──────────────────────────────────────────

@riverpod
class FontNetworkTasks extends _$FontNetworkTasks {
  final Map<String, CancelToken> _tokens = {};

  @override
  int build() => 0;

  void register(String key, CancelToken token) {
    _tokens[key]?.cancel();
    _tokens[key] = token;
  }

  void unregister(String key, CancelToken token) {
    if (identical(_tokens[key], token)) {
      _tokens.remove(key);
    }
  }

  void cancelAll() {
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
  }
}

// ──────────────────────────────────────────
// 已下载字体的元数据缓存
// ──────────────────────────────────────────

@riverpod
class DownloadedFontMetas extends _$DownloadedFontMetas {
  @override
  Map<String, FontItem> build() {
    return _readMetasFromStorage();
  }

  static Map<String, FontItem> _readMetasFromStorage() {
    final raw = AppSettings.getSetting<Object?>(SettingKey.downloadedFontsMeta);
    if (raw is! Map) return {};
    final result = <String, FontItem>{};
    raw.forEach((k, v) {
      if (v is Map) {
        try {
          result[k.toString()] =
              FontItem.fromJson(Map<String, dynamic>.from(v));
        } catch (_) {
          // 元数据损坏则跳过，不影响其他条目
        }
      }
    });
    return result;
  }

  Map<String, dynamic> _readRawMap() {
    final raw = AppSettings.getSetting<Object?>(SettingKey.downloadedFontsMeta);
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Future<void> save(FontItem font) async {
    final map = _readRawMap();
    map[font.id] = font.toJson();
    await AppSettings.setSetting(SettingKey.downloadedFontsMeta, map);
    state = {...state, font.id: font};
  }

  Future<void> remove(String fontId) async {
    final map = _readRawMap();
    if (map.remove(fontId) == null && !state.containsKey(fontId)) return;
    await AppSettings.setSetting(SettingKey.downloadedFontsMeta, map);
    final next = Map<String, FontItem>.from(state)..remove(fontId);
    state = next;
  }

  /// 计算"已下载但不在远程列表"的孤立字体。
  ///
  /// 兼容旧版本（仅有路径、无元数据）的数据：对此类条目合成占位 [FontItem]，
  /// 至少保证用户仍能在 UI 中看到并删除它们。
  List<FontItem> orphansFor(Set<String> remoteIds) {
    final pathsRaw =
        AppSettings.getSetting<Object?>(SettingKey.downloadedFonts);
    final pathIds = pathsRaw is Map
        ? pathsRaw.keys.map((e) => e.toString()).toSet()
        : <String>{};
    final candidateIds = <String>{...state.keys, ...pathIds}
      ..removeAll(remoteIds);
    return candidateIds.map((id) {
      final meta = state[id];
      if (meta != null) return meta;
      return FontItem(
        id: id,
        name: id,
        family: id,
        author: '未知',
        preview: '',
        font: '',
        size: 0,
      );
    }).toList();
  }

  /// 为已存在于 [SettingKey.downloadedFonts] 但缺失元数据的旧版本数据回填信息。
  Future<void> backfillFromRemote(List<FontItem> remote) async {
    final paths = AppSettings.getSetting<Object?>(SettingKey.downloadedFonts);
    if (paths is! Map || paths.isEmpty) return;
    final pathKeys = paths.keys.map((e) => e.toString()).toSet();
    final map = _readRawMap();
    final next = Map<String, FontItem>.from(state);
    var changed = false;
    for (final font in remote) {
      if (!pathKeys.contains(font.id)) continue;
      if (map.containsKey(font.id)) continue;
      map[font.id] = font.toJson();
      next[font.id] = font;
      changed = true;
    }
    if (!changed) return;
    await AppSettings.setSetting(SettingKey.downloadedFontsMeta, map);
    state = next;
  }
}

// ──────────────────────────────────────────
// 单个字体下载状态 provider（family by fontId）
// ──────────────────────────────────────────

@riverpod
class FontDownload extends _$FontDownload {
  @override
  FontDownloadState build(String fontId) {
    final savedPaths = _getSavedPaths();
    final filePath = savedPaths[fontId];
    if (filePath != null && File(filePath).existsSync()) {
      return FontDownloadState(
        status: FontDownloadStatus.done,
        filePath: filePath,
        progress: 1.0,
      );
    }
    return const FontDownloadState();
  }

  Map<String, String> _getSavedPaths() {
    final raw = AppSettings.getSetting<Object?>(SettingKey.downloadedFonts);
    if (raw is Map) {
      return Map<String, String>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
      );
    }
    return {};
  }

  Future<void> download(FontItem font) async {
    if (state.status == FontDownloadStatus.downloading ||
        state.status == FontDownloadStatus.done) {
      return;
    }
    // 切换线路期间字体列表会暂时卸载，保留下载状态直到旧请求完成清理。
    final keepAlive = ref.keepAlive();
    final mirror = AppSettings.fontRepoMirror;
    final tasks = ref.read(fontNetworkTasksProvider.notifier);
    final taskKey = 'download:$fontId';
    final cancelToken = CancelToken();
    tasks.register(taskKey, cancelToken);

    state = const FontDownloadState(
      status: FontDownloadStatus.downloading,
      progress: 0.0,
    );

    String? filePath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/animeflow_fonts');
      await fontsDir.create(recursive: true);
      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
      filePath = '${fontsDir.path}/${font.id}.ttf';
      await GithubApi.downloadFontToFile(
        font.font,
        filePath,
        mirror: mirror,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (cancelToken.isCancelled || total <= 0) return;
          state = state.copyWith(
            status: FontDownloadStatus.downloading,
            progress: received / total,
          );
        },
      );

      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
      tasks.unregister(taskKey, cancelToken);
      final savedPaths = _getSavedPaths();
      savedPaths[font.id] = filePath;
      await AppSettings.setSetting(SettingKey.downloadedFonts, savedPaths);
      await ref.read(downloadedFontMetasProvider.notifier).save(font);

      state = FontDownloadState(
        status: FontDownloadStatus.done,
        filePath: filePath,
        progress: 1.0,
      );
    } catch (e) {
      if (filePath != null) await _deletePartialFile(filePath);
      if (cancelToken.isCancelled ||
          e is DioException && CancelToken.isCancel(e)) {
        state = const FontDownloadState();
        return;
      }
      state = FontDownloadState(
        status: FontDownloadStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      tasks.unregister(taskKey, cancelToken);
      keepAlive.close();
    }
  }

  Future<void> _deletePartialFile(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// 删除本地字体文件；若正在使用该字体则恢复系统字体。
  ///
  /// 不依赖远程返回的 [FontItem]，仅凭 family 参数的 [fontId] + 本地存储即可清理，
  /// 因此远程仓库下架某个字体后，本地仍能正常删除其文件与配置。
  Future<void> deleteDownload() async {
    final savedPaths = _getSavedPaths();
    final filePath = savedPaths.remove(fontId) ?? state.filePath;

    if (filePath != null) {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    await AppSettings.setSetting(SettingKey.downloadedFonts, savedPaths);
    await ref.read(downloadedFontMetasProvider.notifier).remove(fontId);

    final selectedId =
        AppSettings.getSetting<Object?>(SettingKey.selectedFontId) as String?;
    if (selectedId == fontId) {
      await ref.read(selectedFontProvider.notifier).clearFont();
    }

    state = const FontDownloadState();
  }
}

// ──────────────────────────────────────────
// 已选字体 provider（全局持久化）
// ──────────────────────────────────────────

@riverpod
class SelectedFont extends _$SelectedFont {
  /// 在 [Storage.init] 之后、[runApp] 之前调用，注册已持久化的自定义字体。
  static Future<void> initOnStartup() async {
    try {
      final fontFamily =
          AppSettings.getSetting<Object?>(SettingKey.fontFamily) as String?;
      final fontId =
          AppSettings.getSetting<Object?>(SettingKey.selectedFontId) as String?;
      if (fontFamily == null || fontId == null) return;

      final raw = AppSettings.getSetting<Object?>(SettingKey.downloadedFonts);
      if (raw is! Map) return;

      final savedPaths = Map<String, String>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
      );

      final filePath = savedPaths[fontId];
      if (filePath == null) return;

      final file = File(filePath);
      if (!file.existsSync()) {
        await AppSettings.deleteSetting(SettingKey.fontFamily);
        await AppSettings.deleteSetting(SettingKey.selectedFontId);
        return;
      }

      final bytes = await file.readAsBytes();
      final loader = FontLoader(fontFamily)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    } catch (_) {
      // 降级使用系统字体
    }
  }

  @override
  String? build() {
    return AppSettings.getSetting<Object?>(SettingKey.fontFamily) as String?;
  }

  /// 注册字体并持久化选中状态
  Future<void> selectFont(FontItem font, String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final loader = FontLoader(font.family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();

    await AppSettings.setSetting(SettingKey.fontFamily, font.family);
    await AppSettings.setSetting(SettingKey.selectedFontId, font.id);

    state = font.family;
    ref.read(themeProvider.notifier).setFontFamily(font.family);
  }

  /// 清除自定义字体，恢复系统字体
  Future<void> clearFont() async {
    await AppSettings.deleteSetting(SettingKey.fontFamily);
    await AppSettings.deleteSetting(SettingKey.selectedFontId);
    state = null;
    ref.read(themeProvider.notifier).setFontFamily(null);
  }
}
