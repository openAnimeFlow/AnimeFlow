enum BgmCollectionSyncStatus {
  idle,
  running,
  success,
  failed;

  static BgmCollectionSyncStatus fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'RUNNING':
        return BgmCollectionSyncStatus.running;
      case 'SUCCESS':
        return BgmCollectionSyncStatus.success;
      case 'FAILED':
        return BgmCollectionSyncStatus.failed;
      default:
        return BgmCollectionSyncStatus.idle;
    }
  }

  String get label {
    switch (this) {
      case BgmCollectionSyncStatus.idle:
        return '未同步';
      case BgmCollectionSyncStatus.running:
        return '同步中';
      case BgmCollectionSyncStatus.success:
        return '同步完成';
      case BgmCollectionSyncStatus.failed:
        return '同步失败';
    }
  }
}

class BgmCollectionSyncStatusItem {
  final BgmCollectionSyncStatus status;
  final int? userId;
  final int syncedCount;
  final int totalCount;
  final String? message;
  final int? startedAt;
  final int? finishedAt;

  const BgmCollectionSyncStatusItem({
    required this.status,
    this.userId,
    this.syncedCount = 0,
    this.totalCount = 0,
    this.message,
    this.startedAt,
    this.finishedAt,
  });

  bool get isRunning => status == BgmCollectionSyncStatus.running;

  factory BgmCollectionSyncStatusItem.fromJson(Map<String, dynamic> json) {
    return BgmCollectionSyncStatusItem(
      status: BgmCollectionSyncStatus.fromJson(json['status'] as String?),
      userId: json['userId'] as int?,
      syncedCount: json['syncedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      message: json['message'] as String?,
      startedAt: json['startedAt'] as int?,
      finishedAt: json['finishedAt'] as int?,
    );
  }
}
