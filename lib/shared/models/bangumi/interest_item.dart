class InterestItem {
  int? id;
  int rate;
  int type;
  String comment;
  List<dynamic> tags;
  int epStatus;
  int volStatus;
  bool private;
  int updatedAt;
  String? remoteSyncStatus;

  InterestItem({
    required this.id,
    required this.rate,
    required this.type,
    required this.comment,
    required this.tags,
    required this.epStatus,
    required this.volStatus,
    required this.private,
    required this.updatedAt,
    this.remoteSyncStatus,
  });

  InterestItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        rate = json['rate'] ?? 0,
        type = json['type'],
        comment = json['comment'] ?? '',
        tags = json['tags'] ?? [],
        epStatus = json['epStatus'] ?? 0,
        volStatus = json['volStatus'] ?? 0,
        private = json['private'] ?? false,
        updatedAt = json['updatedAt'] ?? 0,
        remoteSyncStatus = json['remoteSyncStatus'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rate': rate,
        'type': type,
        'comment': comment,
        'tags': tags,
        'epStatus': epStatus,
        'volStatus': volStatus,
        'private': private,
        'updatedAt': updatedAt,
        'remoteSyncStatus': remoteSyncStatus,
      };
}
