class EpisodesItem {
  final List<EpisodeData> data;
  final int total;

  EpisodesItem({
    required this.data,
    required this.total,
  });

  EpisodesItem.fromJson(Map<String, dynamic> json)
      : data = (json['data'] as List?)
                ?.map((e) => EpisodeData.fromJson(e))
                .toList() ??
            [],
        total = json['total'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

class EpisodeData {
  final int id;
  final int subjectID;
  final num sort;
  final int type;
  final int disc;
  final String name;
  final String? nameCN;
  final String duration;
  final String airdate;
  final int comment;
  final String desc;
  final EpisodeCollection? collection;

  EpisodeData({
    required this.id,
    required this.subjectID,
    required this.sort,
    required this.type,
    required this.disc,
    required this.name,
    this.nameCN,
    required this.duration,
    required this.airdate,
    required this.comment,
    required this.desc,
    this.collection,
  });

  EpisodeData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        subjectID = json['subjectID'],
        sort = json['sort'],
        type = json['type'],
        disc = json['disc'],
        name = json['name'] ?? '',
        nameCN = json['nameCN'],
        duration = json['duration'] ?? '',
        airdate = json['airdate'] ?? '',
        comment = json['comment'] ?? 0,
        desc = json['desc'] ?? '',
        collection = json['collection'] != null
            ? EpisodeCollection.fromJson(json['collection'])
            : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectID': subjectID,
      'sort': sort,
      'type': type,
      'disc': disc,
      'name': name,
      'nameCN': nameCN,
      'duration': duration,
      'airdate': airdate,
      'comment': comment,
      'desc': desc,
      if (collection != null) 'collection': collection!.toJson(),
    };
  }
}

class EpisodeCollection {
  final int status;
  final int? updatedAt;

  EpisodeCollection({
    required this.status,
    this.updatedAt,
  });

  EpisodeCollection.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        updatedAt = json['updatedAt'];

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
