import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../download_directory_platform.dart';

/// Keeps security-scoped bookmarks in native storage and uses coordinated
/// native operations for file-provider directories.
class IosDownloadDirectoryPlatform extends DownloadDirectoryPlatform {
  IosDownloadDirectoryPlatform();

  static const _channel = MethodChannel('anime_flow/download_storage');
  final _paths = <String, String>{};
  Future<void>? _initialization;
  bool _initialized = false;

  @override
  bool get supportsSelection => true;

  @override
  Future<void> initialize() =>
      _initialized ? Future<void>.value() : _initialization ??= _restore();

  Future<void> _restore() async {
    try {
      _paths.addAll(
          await _channel.invokeMapMethod<String, String>('restoreAccess') ??
              {});
      _initialized = true;
    } finally {
      _initialization = null;
    }
  }

  @override
  Future<bool> requestAccess() async {
    await initialize();
    // iOS grants access to a specific directory through the picker.
    return true;
  }

  @override
  Future<String?> selectDirectory({required String dialogTitle}) async {
    await initialize();
    final selected = await _channel.invokeMapMethod<String, dynamic>(
      'selectDirectory',
      {'title': dialogTitle},
    );
    if (selected == null) return null;
    _paths.addAll(Map<String, String>.from(selected['paths'] as Map));
    return selected['path'] as String;
  }

  @override
  String resolvePath(String path) {
    final roots = _paths.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final root in roots) {
      if (path == root) return _paths[root]!;
      if (p.posix.isWithin(root, path)) {
        return p.posix.join(_paths[root]!, p.posix.relative(path, from: root));
      }
    }
    return path;
  }

  @override
  bool fileExists(String path) {
    // Cloud files may be evicted locally. Materialize them when opening,
    // instead of disabling playback based on a synchronous existence check.
    return _paths.keys.any((root) => p.posix.isWithin(root, path)) ||
        super.fileExists(path);
  }

  @override
  Future<void> verifyWritable(String directory) async {
    try {
      await _call('verifyWritable', directory);
    } on PlatformException {
      throw const DownloadDirectoryNotWritableException();
    }
  }

  @override
  Future<String> prepareDownloadDirectory(String directory) =>
      _pathCall('prepareDownloadDirectory', directory);

  @override
  Future<String> publishDownloadDirectory(String directory) =>
      _pathCall('publishDownloadDirectory', directory);

  @override
  Future<void> discardDownloadStaging(String directory) =>
      _call('discardDownloadStaging', directory);

  @override
  Future<String> prepareForReading(String path) =>
      _pathCall('prepareForReading', path);

  @override
  Future<void> writeTextFile(String path, String contents) =>
      _call('writeTextFile', path, {'contents': contents});

  @override
  Future<void> deleteDirectory(String path) => _call('deleteDirectory', path);

  Future<String> _pathCall(String method, String path) async {
    await initialize();
    final result = await _channel.invokeMethod<String>(
      method,
      {'path': resolvePath(path)},
    );
    if (result == null || result.isEmpty) {
      throw PlatformException(code: 'invalid_path', message: method);
    }
    return result;
  }

  Future<void> _call(String method, String path,
      [Map<String, dynamic> extra = const {}]) async {
    await initialize();
    await _channel.invokeMethod<void>(
      method,
      {'path': resolvePath(path), ...extra},
    );
  }
}
