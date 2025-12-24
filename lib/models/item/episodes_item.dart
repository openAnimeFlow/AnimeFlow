class EpisodesItem {
  EpisodesItem({
    required List<Data> data,
    required int total,
  }) {
    _data = data;
    _total = total;
  }

  EpisodesItem.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data.add(Data.fromJson(v));
      });
    }
    _total = json['total'];
  }

  late List<Data> _data;
  late int _total;

  EpisodesItem copyWith({
    List<Data>? data,
    int? total,
  }) =>
      EpisodesItem(
        data: data ?? _data,
        total: total ?? _total,
      );

  List<Data> get data => _data;
  int get total => _total;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['data'] = _data.map((v) => v.toJson()).toList();
      map['total'] = _total;
    return map;
  }
}

class Data {
  Data({
    required int id,
    required int subjectID,
    required int sort,
    required int type,
    required int disc,
    required String name,
    required String nameCN,
    required String duration,
    required String airdate,
    required int comment,
    required String desc,
    Collection? collection,
  }) {
    _id = id;
    _subjectID = subjectID;
    _sort = sort;
    _type = type;
    _disc = disc;
    _name = name;
    _nameCN = nameCN;
    _duration = duration;
    _airdate = airdate;
    _comment = comment;
    _desc = desc;
    _collection = collection;
  }

  Data.fromJson(dynamic json) {
    _id = json['id'];
    _subjectID = json['subjectID'];
    _sort = json['sort'];
    _type = json['type'];
    _disc = json['disc'];
    _name = json['name'];
    _nameCN = json['nameCN'];
    _duration = json['duration'];
    _airdate = json['airdate'];
    _comment = json['comment'];
    _desc = json['desc'];
    _collection =
        json['collection'] != null ? Collection.fromJson(json['collection']) : null;
  }

  late int _id;
  late int _subjectID;
  late int _sort;
  late int _type;
  late int _disc;
  late String _name;
  late String _nameCN;
  late String _duration;
  late String _airdate;
  late int _comment;
  late String _desc;
  Collection? _collection;

  Data copyWith({
    int? id,
    int? subjectID,
    int? sort,
    int? type,
    int? disc,
    String? name,
    String? nameCN,
    String? duration,
    String? airdate,
    int? comment,
    String? desc,
    Collection? collection,
  }) =>
      Data(
        id: id ?? _id,
        subjectID: subjectID ?? _subjectID,
        sort: sort ?? _sort,
        type: type ?? _type,
        disc: disc ?? _disc,
        name: name ?? _name,
        nameCN: nameCN ?? _nameCN,
        duration: duration ?? _duration,
        airdate: airdate ?? _airdate,
        comment: comment ?? _comment,
        desc: desc ?? _desc,
        collection: collection ?? _collection,
      );

  int get id => _id;
  int get subjectID => _subjectID;
  int get sort => _sort;
  int get type => _type;
  int get disc => _disc;
  String get name => _name;
  String get nameCN => _nameCN;
  String get duration => _duration;
  String get airdate => _airdate;
  int get comment => _comment;
  String get desc => _desc;
  Collection? get collection => _collection;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['subjectID'] = _subjectID;
    map['sort'] = _sort;
    map['type'] = _type;
    map['disc'] = _disc;
    map['name'] = _name;
    map['nameCN'] = _nameCN;
    map['duration'] = _duration;
    map['airdate'] = _airdate;
    map['comment'] = _comment;
    map['desc'] = _desc;
    if (_collection != null) {
      map['collection'] = _collection?.toJson();
    }
    return map;
  }
}

/// status : 2
/// updatedAt : 1761630252

class Collection {
  Collection({
    required int status,
    int? updatedAt,
  }) {
    _status = status;
    _updatedAt = updatedAt;
  }

  Collection.fromJson(dynamic json) {
    _status = json['status'];
    _updatedAt = json['updatedAt'];
  }

  late int _status;
  int? _updatedAt;

  Collection copyWith({
    int? status,
    int? updatedAt,
  }) =>
      Collection(
        status: status ?? _status,
        updatedAt: updatedAt ?? _updatedAt,
      );

  int get status => _status;
  int? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    if (_updatedAt != null) {
      map['updatedAt'] = _updatedAt;
    }
    return map;
  }
}
