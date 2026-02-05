import 'avatar_item.dart';

class UserInfoItem {
  final int id;
  final String username;
  final String nickname;
  final AvatarItem avatar;
  final int group;
  final int joinedAt;
  final String sign;
  final String site;
  final String location;
  final String? bio;
  final List<dynamic> networkServices;
  final Homepage homepage;
  final Stats stats;

  UserInfoItem({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.group,
    required this.joinedAt,
    required this.sign,
    required this.site,
    required this.location,
    this.bio,
    required this.networkServices,
    required this.homepage,
    required this.stats,
  });

  factory UserInfoItem.fromJson(Map<String, dynamic> json) {
    return UserInfoItem(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      avatar: AvatarItem.fromJson(json['avatar']),
      group: json['group'],
      joinedAt: json['joinedAt'],
      sign: json['sign'],
      site: json['site'],
      location: json['location'],
      bio: json['bio'],
      networkServices: json['networkServices'],
      homepage: Homepage.fromJson(json['homepage']),
      stats: Stats.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar.toJson(),
      'group': group,
      'joinedAt': joinedAt,
      'sign': sign,
      'site': site,
      'location': location,
      'bio': bio,
      'networkServices': networkServices,
      'homepage': homepage.toJson(),
      'stats': stats.toJson(),
    };
  }
}

class Homepage {
  final List<String> left;
  final List<String> right;

  Homepage({
    required this.left,
    required this.right,
  });

  factory Homepage.fromJson(Map<String, dynamic> json) {
    return Homepage(
      left: List<String>.from(json['left']),
      right: List<String>.from(json['right']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'right': right,
    };
  }
}

class Stats {
  final Subject subject;
  final Mono mono;
  final int blog;
  final int friend;
  final int group;
  final Index index;

  Stats({
    required this.subject,
    required this.mono,
    required this.blog,
    required this.friend,
    required this.group,
    required this.index,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      subject: Subject.fromJson(json['subject']),
      mono: Mono.fromJson(json['mono']),
      blog: json['blog'],
      friend: json['friend'],
      group: json['group'],
      index: Index.fromJson(json['index']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject.toJson(),
      'mono': mono.toJson(),
      'blog': blog,
      'friend': friend,
      'group': group,
      'index': index.toJson(),
    };
  }
}

class Subject {
  final SubjectDetails one;
  final SubjectDetails two;
  final SubjectDetails three;
  final SubjectDetails four;
  final SubjectDetails six;

  Subject({
    required this.one,
    required this.two,
    required this.three,
    required this.four,
    required this.six,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      one: SubjectDetails.fromJson(json['1']),
      two: SubjectDetails.fromJson(json['2']),
      three: SubjectDetails.fromJson(json['3']),
      four: SubjectDetails.fromJson(json['4']),
      six: SubjectDetails.fromJson(json['6']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '1': one.toJson(),
      '2': two.toJson(),
      '3': three.toJson(),
      '4': four.toJson(),
      '6': six.toJson(),
    };
  }
}

class SubjectDetails {
  final int one;
  final int two;
  final int three;
  final int four;
  final int five;

  SubjectDetails({
    required this.one,
    required this.two,
    required this.three,
    required this.four,
    required this.five,
  });

  factory SubjectDetails.fromJson(Map<String, dynamic> json) {
    return SubjectDetails(
      one: json['1'],
      two: json['2'],
      three: json['3'],
      four: json['4'],
      five: json['5'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '1': one,
      '2': two,
      '3': three,
      '4': four,
      '5': five,
    };
  }
}

class Mono {
  final int character;
  final int person;

  Mono({
    required this.character,
    required this.person,
  });

  factory Mono.fromJson(Map<String, dynamic> json) {
    return Mono(
      character: json['character'],
      person: json['person'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character': character,
      'person': person,
    };
  }
}

class Index {
  final int create;
  final int collect;

  Index({
    required this.create,
    required this.collect,
  });

  factory Index.fromJson(Map<String, dynamic> json) {
    return Index(
      create: json['create'],
      collect: json['collect'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'create': create,
      'collect': collect,
    };
  }
}
