class EpisodesItem {
  final List<EpisodeData> data;
  final int total;

  EpisodesItem({
    required this.data,
    required this.total,
  });

  EpisodesItem copyWith({
    List<EpisodeData>? data,
    int? total,
  }) {
    return EpisodesItem(
      data: data ?? this.data,
      total: total ?? this.total,
    );
  }

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
  final String nameCN;
  final String duration;
  final String airdate;
  final int comment;
  final bool? watched;
  final String desc;

  EpisodeData({
    required this.id,
    required this.subjectID,
    required this.sort,
    required this.type,
    required this.disc,
    required this.name,
    required this.nameCN,
    required this.duration,
    required this.airdate,
    required this.comment,
    required this.desc,
    this.watched,
  });

  EpisodeData copyWith({
    int? id,
    int? subjectID,
    num? sort,
    int? type,
    int? disc,
    String? name,
    String? nameCN,
    String? duration,
    String? airdate,
    int? comment,
    bool? watched,
    String? desc,
  }) {
    return EpisodeData(
      id: id ?? this.id,
      subjectID: subjectID ?? this.subjectID,
      sort: sort ?? this.sort,
      type: type ?? this.type,
      disc: disc ?? this.disc,
      name: name ?? this.name,
      nameCN: nameCN ?? this.nameCN,
      duration: duration ?? this.duration,
      airdate: airdate ?? this.airdate,
      comment: comment ?? this.comment,
      watched: watched ?? this.watched,
      desc: desc ?? this.desc,
    );
  }

  EpisodeData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        subjectID = json['subjectID'],
        sort = json['sort'],
        type = json['type'],
        disc = json['disc'],
        watched = json['watched'] as bool?,
        name = json['name'] ?? '',
        nameCN = json['nameCN'] ?? '',
        duration = json['duration'] ?? '',
        airdate = json['airdate'] ?? '',
        comment = json['comment'] ?? 0,
        desc = json['desc'] ?? '';

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
      if (watched != null) 'watched': watched,
      'desc': desc,
    };
  }
}
