import 'package:anime_flow/models/item/bangumi/image_item.dart';

class SubjectItem {
  final List<Subject> data;
  final int total;

  SubjectItem({
    required this.data,
    required this.total,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      data: (json['data'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
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

  @override
  String toString() {
    return 'SubjectItem{data: $data, total: $total}';
  }
}

class Subject {
  final int id;
  final String name;
  final String? nameCN;
  final int type;
  final String info;
  final Rating rating;
  final bool locked;
  final bool nsfw;
  final ImageItem images;

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
      nameCN: json['nameCN'] as String?,
      type: json['type'] as int,
      info: json['info'] as String,
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
      locked: json['locked'] as bool,
      nsfw: json['nsfw'] as bool,
      images: ImageItem.fromJson(json['images'] as Map<String, dynamic>),
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
