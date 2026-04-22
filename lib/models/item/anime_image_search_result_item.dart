class AnimeImageSearchResultItem {
  final int frameCount;
  final String error;
  final List<AnimeImageSearchMatchItem> result;

  AnimeImageSearchResultItem({
    required this.frameCount,
    required this.error,
    required this.result,
  });

  factory AnimeImageSearchResultItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> resultList = (json['result'] as List<dynamic>?) ?? [];
    return AnimeImageSearchResultItem(
      frameCount: _asInt(json['frameCount']) ?? 0,
      error: (json['error'] as String?) ?? '',
      result: resultList
          .map((item) =>
              AnimeImageSearchMatchItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frameCount': frameCount,
      'error': error,
      'result': result.map((item) => item.toJson()).toList(),
    };
  }
}

class AnimeImageSearchMatchItem {
  final AnimeImageSearchAnilistItem? anilist;
  final String filename;
  final List<double> episodes;
  final double from;
  final double at;
  final double to;
  final double duration;
  final double similarity;
  final String video;
  final String image;

  AnimeImageSearchMatchItem({
    required this.anilist,
    required this.filename,
    required this.episodes,
    required this.from,
    required this.at,
    required this.to,
    required this.duration,
    required this.similarity,
    required this.video,
    required this.image,
  });

  factory AnimeImageSearchMatchItem.fromJson(Map<String, dynamic> json) {
    return AnimeImageSearchMatchItem(
      anilist: _parseAnilist(json['anilist']),
      filename: (json['filename'] as String?) ?? '',
      episodes: _asDoubleList(json['episode']),
      from: _asDouble(json['from']) ?? 0,
      at: _asDouble(json['at']) ?? 0,
      to: _asDouble(json['to']) ?? 0,
      duration: _asDouble(json['duration']) ?? 0,
      similarity: _asDouble(json['similarity']) ?? 0,
      video: (json['video'] as String?) ?? '',
      image: (json['image'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anilist': anilist?.toJson(),
      'filename': filename,
      'episode': episodes.map((item) {
        if (item % 1 == 0) return item.toInt();
        return item;
      }).toList(),
      'from': from,
      'at': at,
      'to': to,
      'duration': duration,
      'similarity': similarity,
      'video': video,
      'image': image,
    };
  }
}

class AnimeImageSearchAnilistItem {
  final int id;
  final String type;
  final int? idMal;
  final AnimeImageSearchTitleItem title;
  final String format;
  final String status;
  final String siteUrl;
  final AnimeImageSearchCoverImageItem? coverImage;
  final String? bannerImage;
  final int? episodes;
  final int? duration;
  final bool isAdult;

  AnimeImageSearchAnilistItem({
    required this.id,
    required this.type,
    required this.idMal,
    required this.title,
    required this.format,
    required this.status,
    required this.siteUrl,
    required this.coverImage,
    required this.bannerImage,
    required this.episodes,
    required this.duration,
    required this.isAdult,
  });

  factory AnimeImageSearchAnilistItem.fromJson(Map<String, dynamic> json) {
    return AnimeImageSearchAnilistItem(
      id: _asInt(json['id']) ?? 0,
      type: (json['type'] as String?) ?? '',
      idMal: _asInt(json['idMal']),
      title: AnimeImageSearchTitleItem.fromJson(
          (json['title'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
      format: (json['format'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      siteUrl: (json['siteUrl'] as String?) ?? '',
      coverImage: _asMap(json['coverImage']) == null
          ? null
          : AnimeImageSearchCoverImageItem.fromJson(
              _asMap(json['coverImage'])!),
      bannerImage: json['bannerImage'] as String?,
      episodes: _asInt(json['episodes']),
      duration: _asInt(json['duration']),
      isAdult: json['isAdult'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'idMal': idMal,
      'title': title.toJson(),
      'format': format,
      'status': status,
      'siteUrl': siteUrl,
      'coverImage': coverImage?.toJson(),
      'bannerImage': bannerImage,
      'episodes': episodes,
      'duration': duration,
      'isAdult': isAdult,
    };
  }
}

class AnimeImageSearchTitleItem {
  final String native;
  final String romaji;
  final String chinese;
  final String english;

  AnimeImageSearchTitleItem({
    required this.native,
    required this.romaji,
    required this.chinese,
    required this.english,
  });

  factory AnimeImageSearchTitleItem.fromJson(Map<String, dynamic> json) {
    return AnimeImageSearchTitleItem(
      native: (json['native'] as String?) ?? '',
      romaji: (json['romaji'] as String?) ?? '',
      chinese: (json['chinese'] as String?) ?? '',
      english: (json['english'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'native': native,
      'romaji': romaji,
      'chinese': chinese,
      'english': english,
    };
  }
}

class AnimeImageSearchCoverImageItem {
  final String large;
  final String medium;
  final String extraLarge;
  final String color;

  AnimeImageSearchCoverImageItem({
    required this.large,
    required this.medium,
    required this.extraLarge,
    required this.color,
  });

  factory AnimeImageSearchCoverImageItem.fromJson(Map<String, dynamic> json) {
    return AnimeImageSearchCoverImageItem(
      large: (json['large'] as String?) ?? '',
      medium: (json['medium'] as String?) ?? '',
      extraLarge: (json['extraLarge'] as String?) ?? '',
      color: (json['color'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'medium': medium,
      'extraLarge': extraLarge,
      'color': color,
    };
  }
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<double> _asDoubleList(dynamic value) {
  if (value == null) return <double>[];
  if (value is List) {
    return value
        .map((item) => _asDouble(item))
        .whereType<double>()
        .toList(growable: false);
  }
  final single = _asDouble(value);
  return single == null ? <double>[] : <double>[single];
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

AnimeImageSearchAnilistItem? _parseAnilist(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return AnimeImageSearchAnilistItem.fromJson(value.cast<String, dynamic>());
  }
  final id = _asInt(value);
  if (id == null) return null;
  return AnimeImageSearchAnilistItem(
    id: id,
    type: '',
    idMal: null,
    title: AnimeImageSearchTitleItem(
      native: '',
      romaji: '',
      chinese: '',
      english: '',
    ),
    format: '',
    status: '',
    siteUrl: '',
    coverImage: null,
    bannerImage: null,
    episodes: null,
    duration: null,
    isAdult: false,
  );
}
