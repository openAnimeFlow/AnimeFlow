import 'package:anime_flow/models/item/bangumi/image_five_item.dart';
class TimelineItem {
  final int id;
  final int uid;
  final int cat;
  final int type;
  final Memo memo;
  final bool batch;
  final Source source;
  final int replies;
  final int createdAt;
  final TimelineUser user;

  TimelineItem({
    required this.id,
    required this.uid,
    required this.cat,
    required this.type,
    required this.memo,
    required this.batch,
    required this.source,
    required this.replies,
    required this.createdAt,
    required this.user,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      id: json['id'] as int,
      uid: json['uid'] as int,
      cat: json['cat'] as int,
      type: json['type'] as int,
      memo: Memo.fromJson(json['memo'] as Map<String, dynamic>),
      batch: json['batch'] as bool,
      source: Source.fromJson(json['source'] as Map<String, dynamic>),
      replies: json['replies'] as int,
      createdAt: json['createdAt'] as int,
      user: TimelineUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'cat': cat,
      'type': type,
      'memo': memo.toJson(),
      'batch': batch,
      'source': source.toJson(),
      'replies': replies,
      'createdAt': createdAt,
      'user': user.toJson(),
    };
  }
}

class Memo {
  final Progress progress;

  Memo({
    required this.progress,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress': progress.toJson(),
    };
  }
}

class Progress {
  final Single single;

  Progress({
    required this.single,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      single: Single.fromJson(json['single'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'single': single.toJson(),
    };
  }
}

class Single {
  final TimelineEpisode episode;
  final TimelineSubject subject;

  Single({
    required this.episode,
    required this.subject,
  });

  factory Single.fromJson(Map<String, dynamic> json) {
    return Single(
      episode: TimelineEpisode.fromJson(json['episode'] as Map<String, dynamic>),
      subject: TimelineSubject.fromJson(json['subject'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episode': episode.toJson(),
      'subject': subject.toJson(),
    };
  }
}

class TimelineEpisode {
  final int id;
  final int subjectID;
  final int sort;
  final int type;
  final int disc;
  final String name;
  final String nameCN;
  final String duration;
  final String airdate;
  final int comment;
  final String desc;

  TimelineEpisode({
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
  });

  factory TimelineEpisode.fromJson(Map<String, dynamic> json) {
    return TimelineEpisode(
      id: json['id'] as int,
      subjectID: json['subjectID'] as int,
      sort: json['sort'] as int,
      type: json['type'] as int,
      disc: json['disc'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String,
      duration: json['duration'] as String,
      airdate: json['airdate'] as String,
      comment: json['comment'] as int,
      desc: json['desc'] as String,
    );
  }

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
    };
  }
}

class TimelineSubject {
  final int id;
  final String name;
  final String nameCN;
  final int type;
  final String info;
  final Rating rating;
  final bool locked;
  final bool nsfw;
  final ImageFiveItem images;

  TimelineSubject({
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

  factory TimelineSubject.fromJson(Map<String, dynamic> json) {
    return TimelineSubject(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String,
      type: json['type'] as int,
      info: json['info'] as String,
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
      locked: json['locked'] as bool,
      nsfw: json['nsfw'] as bool,
      images: ImageFiveItem.fromJson(json['images'] as Map<String, dynamic>),
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
//
// class Images {
//   final String large;
//   final String common;
//   final String medium;
//   final String small;
//   final String grid;
//
//   Images({
//     required this.large,
//     required this.common,
//     required this.medium,
//     required this.small,
//     required this.grid,
//   });
//
//   factory Images.fromJson(Map<String, dynamic> json) {
//     return Images(
//       large: json['large'] as String,
//       common: json['common'] as String,
//       medium: json['medium'] as String,
//       small: json['small'] as String,
//       grid: json['grid'] as String,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'large': large,
//       'common': common,
//       'medium': medium,
//       'small': small,
//       'grid': grid,
//     };
//   }
// }

class Source {
  final String name;
  final String? url;

  Source({
    required this.name,
    this.url,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (url != null) {
      map['url'] = url;
    }
    return map;
  }
}

class TimelineUser {
  final int id;
  final String username;
  final String nickname;
  final Avatar avatar;
  final int group;
  final String sign;
  final int joinedAt;

  TimelineUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.group,
    required this.sign,
    required this.joinedAt,
  });

  factory TimelineUser.fromJson(Map<String, dynamic> json) {
    return TimelineUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
      group: json['group'] as int,
      sign: json['sign'] as String,
      joinedAt: json['joinedAt'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar.toJson(),
      'group': group,
      'sign': sign,
      'joinedAt': joinedAt,
    };
  }
}

class Avatar {
  final String small;
  final String medium;
  final String large;

  Avatar({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      small: json['small'] as String,
      medium: json['medium'] as String,
      large: json['large'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'small': small,
      'medium': medium,
      'large': large,
    };
  }
}

