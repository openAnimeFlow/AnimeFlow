import 'dart:io';

import 'package:anime_flow/features/play/domain/local_video_files.dart';
import 'package:anime_flow/features/play/domain/play_source_selection.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:file_picker/file_picker.dart';

class NativeLocalVideoFiles implements LocalVideoFiles {
  @override
  Future<LocalVideoFile?> pick({required String dialogTitle}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.any,
    );
    if (file == null) return null;
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const FileSystemException('无法获取所选视频的本地文件路径');
    }
    return LocalVideoFile(path: path, name: file.name);
  }

  @override
  Future<void> ensureReadable(LocalVideoFile video) async {
    final source = PlaybackSource.localFile(video.path);
    final handle = await File.fromUri(source.uri).open();
    try {
      if (await handle.readByte() == -1) {
        throw FileSystemException('所选视频文件为空', video.path);
      }
    } finally {
      await handle.close();
    }
  }
}
