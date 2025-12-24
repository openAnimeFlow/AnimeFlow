/// Data class for hot items
class HotItem {
  final List<Data> data;
  final int total;

  HotItem({
    required this.data,
    required this.total,
  });

  factory HotItem.fromJson(Map<String, dynamic> json) {
    var dataList = <Data>[];
    if (json['data'] != null) {
      dataList = (json['data'] as List)
          .map((item) => Data.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return HotItem(
      data: dataList,
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

/// Data class for individual item
class Data {
  final Subject subject;
  final int count;

  Data({
    required this.subject,
    required this.count,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'count': count,
    };
  }
}

/// Subject class containing detailed information
class Subject {
  final int id;
  final String name;
  final String? nameCN;
  final int type;
  final String info;
  final Rating rating;
  final bool locked;
  final bool nsfw;
  final Images images;

  Subject({
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

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String,
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

/// Rating information
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
    var countList = <int>[];
    if (json['count'] != null) {
      countList = (json['count'] as List).cast<int>();
    }
    
    return Rating(
      rank: json['rank'] as int,
      count: countList,
      score: (json['score'] is int) 
          ? (json['score'] as int).toDouble() 
          : json['score'] as double,
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

/// Image URLs
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