/// 存储权限被拒绝
class StoragePermissionDeniedException implements Exception {
  const StoragePermissionDeniedException([
    this.message = '存储权限被拒绝，无法保存图片',
  ]);

  final String message;

  @override
  String toString() => message;
}
