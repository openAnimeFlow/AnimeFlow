class DanmakuAnime {
  int animeId;
  String animeTitle;

  DanmakuAnime({
    required this.animeId,
    required this.animeTitle,
  });

  factory DanmakuAnime.fromJson(Map<String, dynamic> json) {
    return DanmakuAnime(
      animeId: json['animeId'],
      animeTitle: json['animeTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'animeTitle': animeTitle,
    };
  }
}

class DanmakuSearchResponse {
  List<DanmakuAnime> animes;
  int errorCode;
  bool success;
  String errorMessage;

  DanmakuSearchResponse({
    required this.animes,
    required this.errorCode,
    required this.success,
    required this.errorMessage,
  });

  factory DanmakuSearchResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['animes'] as List?) ?? const [];
    List<DanmakuAnime> animeList =
        list.map((i) => DanmakuAnime.fromJson(i)).toList();

    return DanmakuSearchResponse(
      animes: animeList,
      errorCode: json['errorCode'],
      success: json['success'],
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animes': animes.map((anime) => anime.toJson()).toList(),
      'errorCode': errorCode,
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}
