class InterestItem {
  int id;
  int rate;
  int type;
  String comment;
  List<dynamic> tags;
  int epStatus;
  int volStatus;
  bool private;
  int updatedAt;

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
  });

  InterestItem.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        rate = json['rate'],
        type = json['type'],
        comment = json['comment'],
        tags = json['tags'],
        epStatus = json['epStatus'],
        volStatus = json['volStatus'],
        private = json['private'] ?? false,
        updatedAt = json['updatedAt'];

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
  };
}
