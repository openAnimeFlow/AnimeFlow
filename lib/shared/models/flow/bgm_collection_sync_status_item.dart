enum BgmCollectionSyncStatus {
  idle,
  queued,
  running,
  waitingConflict,
  partialFailed,
  success,
  failed,
  cancelled,
  unknown;

  static BgmCollectionSyncStatus fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'RUNNING':
        return BgmCollectionSyncStatus.running;
      case 'QUEUED':
        return BgmCollectionSyncStatus.queued;
      case 'WAITING_CONFLICT':
        return BgmCollectionSyncStatus.waitingConflict;
      case 'PARTIAL_FAILED':
        return BgmCollectionSyncStatus.partialFailed;
      case 'SUCCESS':
        return BgmCollectionSyncStatus.success;
      case 'FAILED':
        return BgmCollectionSyncStatus.failed;
      case 'CANCELLED':
        return BgmCollectionSyncStatus.cancelled;
      case 'IDLE':
        return BgmCollectionSyncStatus.idle;
      default:
        return BgmCollectionSyncStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case BgmCollectionSyncStatus.unknown:
        return '未知状态';
      case BgmCollectionSyncStatus.idle:
        return '未同步';
      case BgmCollectionSyncStatus.queued:
        return '排队中';
      case BgmCollectionSyncStatus.running:
        return '同步中';
      case BgmCollectionSyncStatus.waitingConflict:
        return '等待处理冲突';
      case BgmCollectionSyncStatus.partialFailed:
        return '部分失败';
      case BgmCollectionSyncStatus.success:
        return '同步完成';
      case BgmCollectionSyncStatus.failed:
        return '同步失败';
      case BgmCollectionSyncStatus.cancelled:
        return '已取消';
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
  final int? taskId;
  final String? phase;
  final int pendingConflictCount;
  final int failedCount;
  final int? statusVersion;

  const BgmCollectionSyncStatusItem({
    required this.status,
    this.userId,
    this.syncedCount = 0,
    this.totalCount = 0,
    this.message,
    this.startedAt,
    this.finishedAt,
    this.taskId,
    this.phase,
    this.pendingConflictCount = 0,
    this.failedCount = 0,
    this.statusVersion,
  });

  bool get isRunning =>
      status == BgmCollectionSyncStatus.running ||
      status == BgmCollectionSyncStatus.queued;

  /// 非终态任务可在后台恢复，或由另一台设备提交冲突决议。
  bool get shouldPoll =>
      isRunning ||
      status == BgmCollectionSyncStatus.partialFailed ||
      status == BgmCollectionSyncStatus.waitingConflict;

  factory BgmCollectionSyncStatusItem.fromJson(Map<String, dynamic> json) {
    return BgmCollectionSyncStatusItem(
      status: BgmCollectionSyncStatus.fromJson(json['status'] as String?),
      userId: json['userId'] as int?,
      syncedCount: json['syncedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      message: json['message'] as String?,
      startedAt: json['startedAt'] as int?,
      finishedAt: json['finishedAt'] as int?,
      taskId: (json['taskId'] as num?)?.toInt(),
      phase: json['phase'] as String?,
      pendingConflictCount:
          (json['pendingConflictCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      statusVersion: (json['statusVersion'] as num?)?.toInt(),
    );
  }
}
