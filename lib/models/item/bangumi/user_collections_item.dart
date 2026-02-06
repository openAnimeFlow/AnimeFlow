import 'image_five_item.dart';
import 'rating_item.dart';

class UserCollectionsItem {
  final List<UserCollectionData> data;
  final int total;

  UserCollectionsItem({
    required this.data,
    required this.total,
  });

  UserCollectionsItem.fromJson(Map<String, dynamic> json)
      : data = (json['data'] as List?)
                ?.map((e) => UserCollectionData.fromJson(e))
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

class UserCollectionData {
  final int id;
  final String name;
  final String? nameCN;
  final int type;
  final String info;
  final RatingItem rating;
  final bool locked;
  final bool nsfw;
  final ImageFiveItem images;
  final UserCollectionInterest interest;

  UserCollectionData({
    required this.id,
    required this.name,
    this.nameCN,
    required this.type,
    required this.info,
    required this.rating,
    required this.locked,
    required this.nsfw,
    required this.images,
    required this.interest,
  });

  UserCollectionData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'] ?? '',
        nameCN = json['nameCN'] as String?,
        type = json['type'],
        info = json['info'] ?? '',
        rating = RatingItem.fromJson(json['rating']),
        locked = json['locked'] ?? false,
        nsfw = json['nsfw'] ?? false,
        images = ImageFiveItem.fromJson(json['images']),
        interest = UserCollectionInterest.fromJson(json['interest']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (nameCN != null) 'nameCN': nameCN,
      'type': type,
      'info': info,
      'rating': rating.toJson(),
      'locked': locked,
      'nsfw': nsfw,
      'images': images.toJson(),
      'interest': interest.toJson(),
    };
  }
}

class UserCollectionInterest {
  final int id;
  final int rate;
  final int type;
  final String comment;
  final List<String> tags;
  final int updatedAt;

  UserCollectionInterest({
    required this.id,
    required this.rate,
    required this.type,
    required this.comment,
    required this.tags,
    required this.updatedAt,
  });

  UserCollectionInterest.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        rate = json['rate'] ?? 0,
        type = json['type'],
        comment = json['comment'] ?? '',
        tags = List<String>.from(json['tags'] ?? []),
        updatedAt = json['updatedAt'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rate': rate,
      'type': type,
      'comment': comment,
      'tags': tags,
      'updatedAt': updatedAt,
    };
  }
}
