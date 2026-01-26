import 'package:anime_flow/models/item/bangumi/image_four_item.dart';

/// 角色详情数据类
class CharacterDetailItem {
  final int id;
  final String name;
  final String? nameCN;
  final int role;
  final List<InfoboxItem> infobox;
  final String info;
  final String summary;
  final int comment;
  final int collects;
  final bool lock;
  final int redirect;
  final bool nsfw;
  final ImageFourItem images;

  CharacterDetailItem({
    required this.id,
    required this.name,
    this.nameCN,
    required this.role,
    required this.infobox,
    required this.info,
    required this.summary,
    required this.comment,
    required this.collects,
    required this.lock,
    required this.redirect,
    required this.nsfw,
    required this.images,
  });

  factory CharacterDetailItem.fromJson(Map<String, dynamic> json) {
    return CharacterDetailItem(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String?,
      role: json['role'] as int,
      infobox: json['infobox'] != null
          ? (json['infobox'] as List)
              .map((item) => InfoboxItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : <InfoboxItem>[],
      info: json['info'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      comment: json['comment'] as int,
      collects: json['collects'] as int,
      lock: json['lock'] as bool? ?? false,
      redirect: json['redirect'] as int? ?? 0,
      nsfw: json['nsfw'] as bool? ?? false,
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
      'infobox': infobox.map((e) => e.toJson()).toList(),
      'info': info,
      'summary': summary,
      'comment': comment,
      'collects': collects,
      'lock': lock,
      'redirect': redirect,
      'nsfw': nsfw,
      'images': images.toJson(),
    };
  }
}

/// 信息框项
class InfoboxItem {
  final String key;
  final List<InfoboxValue> values;

  InfoboxItem({
    required this.key,
    required this.values,
  });

  factory InfoboxItem.fromJson(Map<String, dynamic> json) {
    return InfoboxItem(
      key: json['key'] as String,
      values: json['values'] != null
          ? (json['values'] as List)
              .map((item) => InfoboxValue.fromJson(item as Map<String, dynamic>))
              .toList()
          : <InfoboxValue>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'values': values.map((e) => e.toJson()).toList(),
    };
  }
}

/// 信息框值
class InfoboxValue {
  final String v;
  final String? k;

  InfoboxValue({
    required this.v,
    this.k,
  });

  factory InfoboxValue.fromJson(Map<String, dynamic> json) {
    return InfoboxValue(
      v: json['v'] as String? ?? '',
      k: json['k'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'v': v,
      if (k != null) 'k': k,
    };
  }
}

