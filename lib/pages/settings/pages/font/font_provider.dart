import 'dart:io';

import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/http/requests/github_request.dart';
import 'package:anime_flow/models/item/font_item.dart';
import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_provider.g.dart';

bool _readFontRepoUseCdnFromStorage() {
  final v = Storage.setting.get(SettingKey.fontRepoUseCdn, defaultValue: true);
  if (v is bool) return v;
  if (v is int) return v != 0;
  return true;
}

// ──────────────────────────────────────────
// CDN：开 = jsDelivr；关 = 直连 Raw（走 GitHub 镜像）
// ──────────────────────────────────────────

@riverpod
class FontRepoCdn extends _$FontRepoCdn {
  @override
  bool build() => _readFontRepoUseCdnFromStorage();

  void setEnabled(bool value) {
    Storage.setting.put(SettingKey.fontRepoUseCdn, value);
    state = value;
  }
}

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
    final useCdn = ref.watch(fontRepoCdnProvider);
    return getFontList(useCdn: useCdn);
  }

  Future<List<FontItem>> getFontList({required bool useCdn}) async {
    return GithubRequest.getRepoFonts(useCdn: useCdn);
  }

  Future<void> reload() async {
    final useCdn = ref.read(fontRepoCdnProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => getFontList(useCdn: useCdn));
  }

  /// 仅加载字节用于字体预览（不保存文件）
  Future<List<int>> loadingFont(String fontUrl) async {
    final useCdn = ref.read(fontRepoCdnProvider);
    return GithubRequest.downloadFont(fontUrl, useCdn: useCdn);
  }
}

// ──────────────────────────────────────────
// 单个字体下载状态 provider（family by fontId）
// ──────────────────────────────────────────

@Riverpod(keepAlive: true)
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
    final raw = Storage.setting.get(SettingKey.downloadedFonts);
    if (raw is Map) {
      return Map<String, String>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
      );
    }
    return {};
  }

  Future<void> download(FontItem font) async {
    final useCdn = _readFontRepoUseCdnFromStorage();
    state = const FontDownloadState(
      status: FontDownloadStatus.downloading,
      progress: 0.0,
    );
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/animeflow_fonts');
      if (!fontsDir.existsSync()) {
        fontsDir.createSync(recursive: true);
      }
      final filePath = '${fontsDir.path}/${font.id}.ttf';

      await GithubRequest.downloadFontToFile(
        font.font,
        filePath,
        useCdn: useCdn,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(
              status: FontDownloadStatus.downloading,
              progress: received / total,
            );
          }
        },
      );

      final savedPaths = _getSavedPaths();
      savedPaths[font.id] = filePath;
      await Storage.setting.put(SettingKey.downloadedFonts, savedPaths);

      state = FontDownloadState(
        status: FontDownloadStatus.done,
        filePath: filePath,
        progress: 1.0,
      );
    } catch (e) {
      state = FontDownloadState(
        status: FontDownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除本地字体文件；若正在使用该字体则恢复系统字体。
  Future<void> deleteDownload(FontItem font) async {
    final savedPaths = _getSavedPaths();
    final filePath = savedPaths.remove(font.id) ?? state.filePath;

    if (filePath != null) {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    await Storage.setting.put(SettingKey.downloadedFonts, savedPaths);

    final selectedId = Storage.setting.get(SettingKey.selectedFontId) as String?;
    if (selectedId == font.id) {
      await ref.read(selectedFontProvider.notifier).clearFont();
    }

    state = const FontDownloadState();
  }
}

// ──────────────────────────────────────────
// 已选字体 provider（全局持久化）
// ──────────────────────────────────────────

@Riverpod(keepAlive: true)
class SelectedFont extends _$SelectedFont {
  /// 在 [Storage.init] 之后、[runApp] 之前调用，注册已持久化的自定义字体。
  static Future<void> initOnStartup() async {
    try {
      final fontFamily =
      Storage.setting.get(SettingKey.fontFamily) as String?;
      final fontId =
      Storage.setting.get(SettingKey.selectedFontId) as String?;
      if (fontFamily == null || fontId == null) return;

      final raw = Storage.setting.get(SettingKey.downloadedFonts);
      if (raw is! Map) return;

      final savedPaths = Map<String, String>.fromEntries(
        raw.entries
            .map((e) => MapEntry(e.key.toString(), e.value.toString())),
      );

      final filePath = savedPaths[fontId];
      if (filePath == null) return;

      final file = File(filePath);
      if (!file.existsSync()) {
        await Storage.setting.delete(SettingKey.fontFamily);
        await Storage.setting.delete(SettingKey.selectedFontId);
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
    return Storage.setting.get(SettingKey.fontFamily) as String?;
  }

  /// 注册字体并持久化选中状态
  Future<void> selectFont(FontItem font, String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final loader = FontLoader(font.family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();

    await Storage.setting.put(SettingKey.fontFamily, font.family);
    await Storage.setting.put(SettingKey.selectedFontId, font.id);

    state = font.family;
    ref.read(themeProvider.notifier).setFontFamily(font.family);
  }

  /// 清除自定义字体，恢复系统字体
  Future<void> clearFont() async {
    await Storage.setting.delete(SettingKey.fontFamily);
    await Storage.setting.delete(SettingKey.selectedFontId);
    state = null;
    ref.read(themeProvider.notifier).setFontFamily(null);
  }
}
