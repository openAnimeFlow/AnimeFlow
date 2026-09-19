enum CollectionRemoteSyncStatus {
  localOnly,
  pending,
  synced,
  authRequired,
  conflict,
  unknown;

  String get apiValue => switch (this) {
        localOnly => 'LOCAL_ONLY',
        pending => 'PENDING',
        synced => 'SYNCED',
        authRequired => 'AUTH_REQUIRED',
        conflict => 'CONFLICT',
        unknown => 'UNKNOWN',
      };

  static CollectionRemoteSyncStatus parse(String? value) => switch (value) {
        'LOCAL_ONLY' => localOnly,
        'PENDING' => pending,
        'SYNCED' => synced,
        'AUTH_REQUIRED' => authRequired,
        'CONFLICT' => conflict,
        _ => unknown,
      };
}

class CollectionUpdateResult {
  final CollectionRemoteSyncStatus remoteSyncStatus;
  final int? localVersion;

  const CollectionUpdateResult({
    required this.remoteSyncStatus,
    this.localVersion,
  });

  factory CollectionUpdateResult.fromResponse(dynamic data) {
    // Older servers returned the literal "success". Do not infer remote status.
    if (data == 'success' || data == null) {
      return const CollectionUpdateResult(
        remoteSyncStatus: CollectionRemoteSyncStatus.unknown,
      );
    }
    if (data is! Map<String, dynamic> || data['localSaved'] != true) {
      throw const FormatException('Invalid collection save response');
    }
    return CollectionUpdateResult(
      remoteSyncStatus:
          CollectionRemoteSyncStatus.parse(data['remoteSyncStatus'] as String?),
      localVersion: (data['localVersion'] as num?)?.toInt(),
    );
  }
}
