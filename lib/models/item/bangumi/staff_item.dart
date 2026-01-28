import 'package:anime_flow/models/item/bangumi/image_four_item.dart';

/// Staff item data class
class StaffItem {
  final List<StaffData> data;
  final int total;

  StaffItem({
    required this.data,
    required this.total,
  });

  factory StaffItem.fromJson(Map<String, dynamic> json) {
    var dataList = <StaffData>[];
    if (json['data'] != null) {
      dataList = (json['data'] as List)
          .map((item) => StaffData.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return StaffItem(
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

/// Staff data class containing staff info and positions
class StaffData {
  final Staff staff;
  final List<Position> positions;

  StaffData({
    required this.staff,
    required this.positions,
  });

  factory StaffData.fromJson(Map<String, dynamic> json) {
    return StaffData(
      staff: Staff.fromJson(json['staff'] as Map<String, dynamic>),
      positions: json['positions'] != null
          ? (json['positions'] as List)
          .map((item) => Position.fromJson(item as Map<String, dynamic>))
          .toList()
          : <Position>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff': staff.toJson(),
      'positions': positions.map((e) => e.toJson()).toList(),
    };
  }
}

/// Staff person information
class Staff {
  final int id;
  final String name;
  final String? nameCN;
  final int type;
  final String info;
  final List<String> career;
  final int comment;
  final bool lock;
  final bool nsfw;
  final ImageFourItem? images;

  Staff({
    required this.id,
    required this.name,
    this.nameCN,
    required this.type,
    required this.info,
    required this.career,
    required this.comment,
    required this.lock,
    required this.nsfw,
    this.images,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    ImageFourItem? images;
    if (json['images'] != null) {
      final imagesJson = json['images'] as Map<String, dynamic>;
      // ImageItem 需要 common 字段，但 JSON 中没有，使用 medium 作为默认值
      images = ImageFourItem(
        large: imagesJson['large'] as String? ?? '',
        medium: imagesJson['medium'] as String? ?? '',
        small: imagesJson['small'] as String? ?? '',
        grid: imagesJson['grid'] as String? ?? '',
      );
    }

    return Staff(
      id: json['id'] as int,
      name: json['name'] as String,
      nameCN: json['nameCN'] as String?,
      type: json['type'] as int,
      info: json['info'] as String? ?? '',
      career: json['career'] != null
          ? (json['career'] as List).cast<String>()
          : <String>[],
      comment: json['comment'] as int,
      lock: json['lock'] as bool? ?? false,
      nsfw: json['nsfw'] as bool? ?? false,
      images: images,
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
      if (images != null) 'images': images!.toJson(),
    };
  }
}

/// Position information
class Position {
  final PositionType type;
  final String summary;
  final String appearEps;

  Position({
    required this.type,
    required this.summary,
    required this.appearEps,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      type: PositionType.fromJson(json['type'] as Map<String, dynamic>),
      summary: json['summary'] as String? ?? '',
      appearEps: json['appearEps'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'summary': summary,
      'appearEps': appearEps,
    };
  }
}

/// Position type information
class PositionType {
  final int id;
  final String en;
  final String cn;
  final String jp;

  PositionType({
    required this.id,
    this.en = '',
    this.cn = '',
    this.jp = '',
  });

  factory PositionType.fromJson(Map<String, dynamic> json) {
    return PositionType(
      id: json['id'] as int,
      en: json['en'] as String? ?? '',
      cn: json['cn'] as String? ?? '',
      jp: json['jp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'en': en,
      'cn': cn,
      'jp': jp,
    };
  }
}

