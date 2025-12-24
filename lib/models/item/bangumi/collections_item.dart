class CollectionsItem {
  List<Data> data;
  int total;

  CollectionsItem({required this.data, required this.total});

  CollectionsItem.fromJson(Map<String, dynamic> json) :
        data = (json['data'] as List).map((e) => Data.fromJson(e)).toList(),
        total = json['total'];

  Map<String, dynamic> toJson() => {
    'data': data.map((e) => e.toJson()).toList(),
    'total': total,
  };
}

class Data {
  Airtime airtime;
  Map<String, int> collection;
  int eps;
  int id;
  List<Infobox> infobox;
  String info;
  List<String> metaTags;
  bool locked;
  String name;
  String nameCN;
  bool nsfw;
  Platform platform;
  Rating rating;
  int redirect;
  bool series;
  int seriesEntry;
  String summary;
  int type;
  int volumes;
  List<Tags> tags;
  Images images;
  Interest interest;

  Data({
    required this.airtime,
    required this.collection,
    required this.eps,
    required this.id,
    required this.infobox,
    required this.info,
    required this.metaTags,
    required this.locked,
    required this.name,
    required this.nameCN,
    required this.nsfw,
    required this.platform,
    required this.rating,
    required this.redirect,
    required this.series,
    required this.seriesEntry,
    required this.summary,
    required this.type,
    required this.volumes,
    required this.tags,
    required this.images,
    required this.interest,
  });

  Data.fromJson(Map<String, dynamic> json) :
        airtime = Airtime.fromJson(json['airtime']),
        collection = Map<String, int>.from(json['collection']),
        eps = json['eps'],
        id = json['id'],
        infobox = (json['infobox'] as List).map((e) => Infobox.fromJson(e)).toList(),
        info = json['info'],
        metaTags = List<String>.from(json['metaTags']),
        locked = json['locked'],
        name = json['name'],
        nameCN = json['nameCN'],
        nsfw = json['nsfw'],
        platform = Platform.fromJson(json['platform']),
        rating = Rating.fromJson(json['rating']),
        redirect = json['redirect'],
        series = json['series'],
        seriesEntry = json['seriesEntry'],
        summary = json['summary'],
        type = json['type'],
        volumes = json['volumes'],
        tags = (json['tags'] as List).map((e) => Tags.fromJson(e)).toList(),
        images = Images.fromJson(json['images']),
        interest = Interest.fromJson(json['interest']);

  Map<String, dynamic> toJson() => {
    'airtime': airtime.toJson(),
    'collection': collection,
    'eps': eps,
    'id': id,
    'infobox': infobox.map((e) => e.toJson()).toList(),
    'info': info,
    'metaTags': metaTags,
    'locked': locked,
    'name': name,
    'nameCN': nameCN,
    'nsfw': nsfw,
    'platform': platform.toJson(),
    'rating': rating.toJson(),
    'redirect': redirect,
    'series': series,
    'seriesEntry': seriesEntry,
    'summary': summary,
    'type': type,
    'volumes': volumes,
    'tags': tags.map((e) => e.toJson()).toList(),
    'images': images.toJson(),
    'interest': interest.toJson(),
  };
}

class Airtime {
  String date;
  int month;
  int weekday;
  int year;

  Airtime({
    required this.date,
    required this.month,
    required this.weekday,
    required this.year,
  });

  Airtime.fromJson(Map<String, dynamic> json) :
        date = json['date'],
        month = json['month'],
        weekday = json['weekday'],
        year = json['year'];

  Map<String, dynamic> toJson() => {
    'date': date,
    'month': month,
    'weekday': weekday,
    'year': year,
  };
}

class Infobox {
  String key;
  List<Values> values;

  Infobox({required this.key, required this.values});

  Infobox.fromJson(Map<String, dynamic> json) :
        key = json['key'],
        values = (json['values'] as List).map((e) => Values.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
    'key': key,
    'values': values.map((e) => e.toJson()).toList(),
  };
}

class Values {
  String v;

  Values({required this.v});

  Values.fromJson(Map<String, dynamic> json) : v = json['v'];

  Map<String, dynamic> toJson() => {'v': v};
}

class Platform {
  int id;
  String type;
  String typeCN;
  String alias;
  int order;
  bool enableHeader;
  String wikiTpl;

  Platform({
    required this.id,
    required this.type,
    required this.typeCN,
    required this.alias,
    required this.order,
    required this.enableHeader,
    required this.wikiTpl,
  });

  Platform.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        type = json['type'],
        typeCN = json['typeCN'],
        alias = json['alias'],
        order = json['order'],
        enableHeader = json['enableHeader'],
        wikiTpl = json['wikiTpl'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'typeCN': typeCN,
    'alias': alias,
    'order': order,
    'enableHeader': enableHeader,
    'wikiTpl': wikiTpl,
  };
}

class Rating {
  int rank;
  List<int> count;
  double score;
  int total;

  Rating({
    required this.rank,
    required this.count,
    required this.score,
    required this.total,
  });

  Rating.fromJson(Map<String, dynamic> json) :
        rank = json['rank'],
        count = List<int>.from(json['count']),
        score = json['score'].toDouble(),
        total = json['total'];

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'count': count,
    'score': score,
    'total': total,
  };
}

class Tags {
  String name;
  int count;

  Tags({required this.name, required this.count});

  Tags.fromJson(Map<String, dynamic> json) :
        name = json['name'],
        count = json['count'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'count': count,
  };
}

class Images {
  String large;
  String common;
  String medium;
  String small;
  String grid;

  Images({
    required this.large,
    required this.common,
    required this.medium,
    required this.small,
    required this.grid,
  });

  Images.fromJson(Map<String, dynamic> json) :
        large = json['large'],
        common = json['common'],
        medium = json['medium'],
        small = json['small'],
        grid = json['grid'];

  Map<String, dynamic> toJson() => {
    'large': large,
    'common': common,
    'medium': medium,
    'small': small,
    'grid': grid,
  };
}

class Interest {
  int id;
  int rate;
  int type;
  String comment;
  List<dynamic> tags;
  int epStatus;
  int volStatus;
  bool private;
  int updatedAt;

  Interest({
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

  Interest.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        rate = json['rate'],
        type = json['type'],
        comment = json['comment'],
        tags = json['tags'],
        epStatus = json['epStatus'],
        volStatus = json['volStatus'],
        private = json['private'],
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
