abstract class DownloadDirectoryException implements Exception {
  const DownloadDirectoryException();

  String get code;

  @override
  String toString() => code;
}

class DownloadDirectoryNotWritableException extends DownloadDirectoryException {
  const DownloadDirectoryNotWritableException();

  static const errorCode = 'download_directory_not_writable';

  @override
  String get code => errorCode;
}

class DownloadDirectoryAccessException extends DownloadDirectoryException {
  const DownloadDirectoryAccessException();

  static const errorCode = 'download_directory_access_denied';

  @override
  String get code => errorCode;
}
