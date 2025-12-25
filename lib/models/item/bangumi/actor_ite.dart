class CharactersItem {
  final List<CharacterActorData> data;
  final int total;

  CharactersItem({
    required this.data,
    required this.total,
  });

  factory CharactersItem.fromJson(Map<String, dynamic> json) {
    return CharactersItem(
      data: json['data'] != null
          ? (json['data'] as List).map((item) => CharacterActorData.fromJson(item as Map<String, dynamic>)).toList()
          : <CharacterActorData>[],
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }
}

class CharacterActorData {
  final Character character;
  final List<Actor> actors;
  final int type;
  final int order;

  CharacterActorData({
    required this.character,
    required this.actors,
    required this.type,
    required this.order,
  });

  factory CharacterActorData.fromJson(Map<String, dynamic> json) {
    return CharacterActorData(
      character: json['character'] != null
          ? Character.fromJson(json['character'] as Map<String, dynamic>)
          : Character(
              id: 0,
              name: '',
              nameCN: '',
              role: 0,
              info: '',
              comment: 0,
              lock: false,
              nsfw: false,
              images: Images(large: '', medium: '', small: '', grid: ''),
            ),
      actors: json['actors'] != null
          ? (json['actors'] as List).map((item) => Actor.fromJson(item as Map<String, dynamic>)).toList()
          : <Actor>[],
      type: json['type'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character': character.toJson(),
      'actors': actors.map((item) => item.toJson()).toList(),
      'type': type,
      'order': order,
    };
  }
}

class Character {
  final int id;
  final String name;
  final String nameCN;
  final int role;
  final String info;
  final int comment;
  final bool lock;
  final bool nsfw;
  final Images images;

  Character({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.role,
    required this.info,
    required this.comment,
    required this.lock,
    required this.nsfw,
    required this.images,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String,
      role: json['role'] as int,
      info: json['info'] as String,
      comment: json['comment'] as int,
      lock: json['lock'] as bool,
      nsfw: json['nsfw'] as bool,
      images: json['images'] != null
          ? Images.fromJson(json['images'] as Map<String, dynamic>)
          : Images(
              large: '',
              medium: '',
              small: '',
              grid: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameCN': nameCN,
      'role': role,
      'info': info,
      'comment': comment,
      'lock': lock,
      'nsfw': nsfw,
      'images': images.toJson(),
    };
  }
}

class Actor {
  final int id;
  final String name;
  final String nameCN;
  final int type;
  final String info;
  final List<String> career;
  final int comment;
  final bool lock;
  final bool nsfw;
  final Images images;

  Actor({
    required this.id,
    required this.name,
    required this.nameCN,
    required this.type,
    required this.info,
    required this.career,
    required this.comment,
    required this.lock,
    required this.nsfw,
    required this.images,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String,
      type: json['type'] as int,
      info: json['info'] as String,
      career: (json['career'] as List).map((item) => item as String).toList(),
      comment: json['comment'] as int,
      lock: json['lock'] as bool,
      nsfw: json['nsfw'] as bool,
      images: json['images'] != null
          ? Images.fromJson(json['images'] as Map<String, dynamic>)
          : Images(
              large: '',
              medium: '',
              small: '',
              grid: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameCN': nameCN,
      'type': type,
      'info': info,
      'career': career,
      'comment': comment,
      'lock': lock,
      'nsfw': nsfw,
      'images': images.toJson(),
    };
  }
}

class Images {
  final String large;
  final String medium;
  final String small;
  final String grid;

  Images({
    required this.large,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory Images.fromJson(Map<String, dynamic> json) {
    return Images(
      large: json['large'] as String,
      medium: json['medium'] as String,
      small: json['small'] as String,
      grid: json['grid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'medium': medium,
      'small': small,
      'grid': grid,
    };
  }
}
