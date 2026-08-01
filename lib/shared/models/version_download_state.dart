class VersionDownloadState {
  final bool isDownloading;
  final double progress;
  final int receivedBytes;
  final int totalBytes;

  const VersionDownloadState({
    this.isDownloading = false,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
  });

  static const idle = VersionDownloadState();
}
