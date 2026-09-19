class CollectionConflictItem {
  final int conflictId;
  final int subjectId;
  final int? subjectType;
  final String? subjectName;
  final String? subjectImage;
  final int? localType;
  final int? remoteType;
  final int? localVersion;
  final int conflictVersion;
  final String? status;

  const CollectionConflictItem({
    required this.conflictId,
    required this.subjectId,
    this.subjectType,
    this.subjectName,
    this.subjectImage,
    this.localType,
    this.remoteType,
    this.localVersion,
    required this.conflictVersion,
    this.status,
  });

  factory CollectionConflictItem.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) => value is num ? value.toInt() : null;
    return CollectionConflictItem(
      conflictId: asInt(json['conflictId']) ?? 0,
      subjectId: asInt(json['subjectId']) ?? 0,
      subjectType: asInt(json['subjectType']),
      subjectName: json['subjectName'] as String?,
      subjectImage: json['subjectImage'] as String?,
      localType: asInt(json['localType']),
      remoteType: asInt(json['remoteType']),
      localVersion: asInt(json['localVersion']),
      conflictVersion: asInt(json['conflictVersion']) ?? 0,
      status: json['status'] as String?,
    );
  }
}
