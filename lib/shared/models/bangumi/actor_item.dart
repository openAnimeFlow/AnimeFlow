import 'package:anime_flow/shared/models/bangumi/image_four_item.dart';

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
          ? (json['data'] as List)
              .map((item) =>
                  CharacterActorData.fromJson(item as Map<String, dynamic>))
              .toList()
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
  final List<CharacterCast> casts;
  final int type;
  final int order;

  CharacterActorData({
    required this.character,
    List<CharacterCast>? casts,
    List<Actor>? actors,
    required this.type,
    required this.order,
  }) : casts = casts ??
            (actors ?? <Actor>[])
                .map((person) => CharacterCast(
                      person: person,
                      relation: 0,
                      summary: '',
                    ))
                .toList();

  /// Keeps existing character views compatible with the casts response.
  List<Actor> get actors => casts.map((cast) => cast.person).toList();

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
              images: ImageFourItem(large: '', medium: '', small: '', grid: ''),
            ),
      casts: json['casts'] != null
          ? (json['casts'] as List)
              .map((item) =>
                  CharacterCast.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      actors: json['casts'] == null && json['actors'] != null
          ? (json['actors'] as List)
              .map((item) => Actor.fromJson(item as Map<String, dynamic>))
              .toList()
          : <Actor>[],
      type: json['type'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character': character.toJson(),
      'casts': casts.map((item) => item.toJson()).toList(),
      'type': type,
      'order': order,
    };
  }
}

class CharacterCast {
  final Actor person;
  final int relation;
  final String summary;

  CharacterCast({
    required this.person,
    required this.relation,
    required this.summary,
  });

  factory CharacterCast.fromJson(Map<String, dynamic> json) {
    return CharacterCast(
      person: Actor.fromJson(json['person'] as Map<String, dynamic>),
      relation: json['relation'] as int,
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person': person.toJson(),
      'relation': relation,
      'summary': summary,
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
  final ImageFourItem images;

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
      nameCN: json['nameCN'] as String? ?? '',
      role: json['role'] as int,
      info: json['info'] as String,
      comment: json['comment'] as int,
      lock: json['lock'] as bool,
      nsfw: json['nsfw'] as bool,
      images: json['images'] != null
          ? ImageFourItem.fromJson(json['images'] as Map<String, dynamic>)
          : ImageFourItem(
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
  final String? nameCN;
  final int type;
  final String info;
  final List<String> career;
  final int comment;
  final bool lock;
  final bool nsfw;
  final ImageFourItem images;

  Actor({
    required this.id,
    required this.name,
    this.nameCN,
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
      nameCN: json['nameCN'] as String?,
      type: json['type'] as int,
      info: json['info'] as String,
      career: json['career'] != null
          ? (json['career'] as List).map((item) => item as String).toList()
          : <String>[],
      comment: json['comment'] as int,
      lock: json['lock'] as bool,
      nsfw: json['nsfw'] as bool,
      images: json['images'] != null
          ? ImageFourItem.fromJson(json['images'] as Map<String, dynamic>)
          : ImageFourItem(
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
