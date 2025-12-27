import 'package:anime_flow/models/item/bangumi/collections_item.dart';

class SubjectsItem {
  final Airtime airtime;
  final Collection collection;
  final int eps;
  final int id;
  final List<Infobox> infobox;
  final String info;
  final List<String> metaTags;
  final bool locked;
  final String name;
  final String nameCN;
  final bool nsfw;
  final Platform platform;
  final Rating rating;
  final int redirect;
  final bool series;
  final int seriesEntry;
  final String summary;
  final int type;
  final int volumes;
  final List<Tags> tags;
  final Images images;
  final Interest? interest;

  SubjectsItem({
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
    this.interest,
  });

  SubjectsItem.fromJson(Map<String, dynamic> json)
      : airtime = Airtime.fromJson(json['airtime']),
        collection = Collection.fromJson(json['collection']),
        eps = json['eps'],
        id = json['id'],
        infobox = (json['infobox'] as List)
            .map((e) => Infobox.fromJson(e))
            .toList(),
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
        interest = json['interest'] != null
            ? Interest.fromJson(json['interest'])
            : null;

  Map<String, dynamic> toJson() {
    return {
      'airtime': airtime.toJson(),
      'collection': collection.toJson(),
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
      if (interest != null) 'interest': interest!.toJson(),
    };
  }
}

class Airtime {
  final String date;
  final int month;
  final int weekday;
  final int year;

  Airtime({
    required this.date,
    required this.month,
    required this.weekday,
    required this.year,
  });

  Airtime.fromJson(Map<String, dynamic> json)
      : date = json['date'],
        month = json['month'],
        weekday = json['weekday'],
        year = json['year'];

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'month': month,
      'weekday': weekday,
      'year': year,
    };
  }
}

class Collection {
  final Map<String, int> data;

  Collection({required this.data});

  Collection.fromJson(Map<String, dynamic> json) : data = Map<String, int>.from(json);

  Map<String, dynamic> toJson() => Map<String, int>.from(data);
}

class Infobox {
  final String key;
  final List<Values> values;

  Infobox({
    required this.key,
    required this.values,
  });

  Infobox.fromJson(Map<String, dynamic> json)
      : key = json['key'],
        values = (json['values'] as List)
            .map((e) => Values.fromJson(e))
            .toList();

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'values': values.map((e) => e.toJson()).toList(),
    };
  }
}

class Values {
  final String v;

  Values({required this.v});

  Values.fromJson(Map<String, dynamic> json) : v = json['v'];

  Map<String, dynamic> toJson() {
    return {'v': v};
  }
}

class Platform {
  final int id;
  final String type;
  final String typeCN;
  final String alias;
  final int order;
  final bool enableHeader;
  final String wikiTpl;

  Platform({
    required this.id,
    required this.type,
    required this.typeCN,
    required this.alias,
    required this.order,
    required this.enableHeader,
    required this.wikiTpl,
  });

  Platform.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        typeCN = json['typeCN'],
        alias = json['alias'],
        order = json['order'],
        enableHeader = json['enableHeader'],
        wikiTpl = json['wikiTpl'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'typeCN': typeCN,
      'alias': alias,
      'order': order,
      'enableHeader': enableHeader,
      'wikiTpl': wikiTpl,
    };
  }
}

class Rating {
  final int rank;
  final List<int> count;
  final double score;
  final int total;

  Rating({
    required this.rank,
    required this.count,
    required this.score,
    required this.total,
  });

  Rating.fromJson(Map<String, dynamic> json)
      : rank = json['rank'],
        count = List<int>.from(json['count']),
        score = json['score'],
        total = json['total'];

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'count': count,
      'score': score,
      'total': total,
    };
  }
}

class Tags {
  final String name;
  final int count;

  Tags({
    required this.name,
    required this.count,
  });

  Tags.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        count = json['count'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }
}

class Images {
  final String large;
  final String common;
  final String medium;
  final String small;
  final String grid;

  Images({
    required this.large,
    required this.common,
    required this.medium,
    required this.small,
    required this.grid,
  });

  Images.fromJson(Map<String, dynamic> json)
      : large = json['large'],
        common = json['common'],
        medium = json['medium'],
        small = json['small'],
        grid = json['grid'];

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'common': common,
      'medium': medium,
      'small': small,
      'grid': grid,
    };
  }
}
