class SubjectItem {
  final List<Data> data;
  final int total;

  SubjectItem({
    required this.data,
    required this.total,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      data: (json['data'] as List<dynamic>)
          .map((e) => Data.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

class Data {
  final int id;
  final String name;
  final String? nameCN;
  final int type;
  final String info;
  final Rating rating;
  final bool locked;
  final bool nsfw;
  final Images images;

  Data({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.type,
    required this.info,
    required this.rating,
    required this.locked,
    required this.nsfw,
    required this.images,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String?,
      type: json['type'] as int,
      info: json['info'] as String,
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
      locked: json['locked'] as bool,
      nsfw: json['nsfw'] as bool,
      images: Images.fromJson(json['images'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameCN': nameCN,
      'type': type,
      'info': info,
      'rating': rating.toJson(),
      'locked': locked,
      'nsfw': nsfw,
      'images': images.toJson(),
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

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rank: json['rank'] as int,
      count: (json['count'] as List<dynamic>).cast<int>(),
      score: (json['score'] as num).toDouble(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'count': count,
      'score': score,
      'total': total,
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

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      large: json['large'] as String,
      common: json['common'] as String,
      medium: json['medium'] as String,
      small: json['small'] as String,
      grid: json['grid'] as String,
    );
  }

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
