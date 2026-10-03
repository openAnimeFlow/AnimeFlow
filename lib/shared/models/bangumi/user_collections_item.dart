import 'image_five_item.dart';
import 'rating_item.dart';
import 'subjects_info_item.dart';

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
  /// 正片总集数；0 表示本地未收录该条目的剧集信息。
  final int totalEpisodes;
  /// 当前用户观看到第几集，已按正片集数封顶。
  final int watchedEpisode;
  /// 连载中番剧的下一集播出日期（yyyy-MM-dd）。
  final String? nextEpisodeAirDate;

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
    this.totalEpisodes = 0,
    this.watchedEpisode = 0,
    this.nextEpisodeAirDate,
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
        interest = UserCollectionInterest.fromJson(json['interest']),
        totalEpisodes = json['totalEpisodes'] ?? 0,
        watchedEpisode = json['watchedEpisode'] ?? 0,
        nextEpisodeAirDate = json['nextEpisodeAirDate'] as String?;

  factory UserCollectionData.fromSubject(SubjectsInfoItem subject) {
    final interest = subject.interest;
    return UserCollectionData(
      id: subject.id,
      name: subject.name,
      nameCN: subject.nameCN,
      type: subject.type,
      info: subject.info,
      rating: subject.rating,
      locked: subject.locked,
      nsfw: subject.nsfw,
      images: subject.images,
      totalEpisodes: subject.eps,
      watchedEpisode: interest?.epStatus ?? 0,
      // 条目接口没有下一集播出信息，只有收藏列表接口会返回。
      nextEpisodeAirDate: null,
      interest: UserCollectionInterest(
        id: interest?.id,
        rate: interest?.rate ?? 0,
        type: interest?.type ?? 0,
        comment: interest?.comment ?? '',
        tags: interest?.tags.whereType<String>().toList() ?? const [],
        updatedAt: interest?.updatedAt ?? 0,
        remoteSyncStatus: interest?.remoteSyncStatus,
      ),
    );
  }

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
      'totalEpisodes': totalEpisodes,
      'watchedEpisode': watchedEpisode,
      'nextEpisodeAirDate': nextEpisodeAirDate,
      'interest': interest.toJson(),
    };
  }
}

class UserCollectionInterest {
  final int? id;
  final int rate;
  final int type;
  final String comment;
  final List<String> tags;
  final int updatedAt;
  final String? remoteSyncStatus;

  UserCollectionInterest({
    required this.id,
    required this.rate,
    required this.type,
    required this.comment,
    required this.tags,
    required this.updatedAt,
    this.remoteSyncStatus,
  });

  UserCollectionInterest.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        rate = json['rate'] ?? 0,
        type = json['type'],
        comment = json['comment'] ?? '',
        tags = List<String>.from(json['tags'] ?? []),
        updatedAt = json['updatedAt'] ?? 0,
        remoteSyncStatus = json['remoteSyncStatus'] as String?;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rate': rate,
      'type': type,
      'comment': comment,
      'tags': tags,
      'updatedAt': updatedAt,
      'remoteSyncStatus': remoteSyncStatus,
    };
  }
}
