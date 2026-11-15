import 'package:anime_flow/features/play/domain/play_source_selection.dart';

abstract interface class LocalVideoFiles {
  Future<LocalVideoFile?> pick({required String dialogTitle});
  Future<void> ensureReadable(LocalVideoFile video);
}
