class SubjectWallpaperPage {
  const SubjectWallpaperPage({
    required this.data,
    required this.page,
    required this.totalPages,
  });

  final List<SubjectWallpaper> data;
  final int page;
  final int totalPages;

  factory SubjectWallpaperPage.fromJson(Map<String, dynamic> json) =>
      SubjectWallpaperPage(
        data: (json['data'] as List)
            .map((item) =>
                SubjectWallpaper.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        page: json['page'] as int,
        totalPages: json['totalPages'] as int,
      );
}

class SubjectWallpaper {
  const SubjectWallpaper({
    required this.subjectId,
    required this.name,
    required this.nameCn,
    required this.posters,
    this.backdrops = const [],
  });

  final int subjectId;
  final String name;
  final String nameCn;
  final List<String> posters;
  final List<String> backdrops;

  /// 每张不同的图片作为一个随机候选，忽略空地址。
  List<String> get coverImages => {...backdrops, ...posters}
      .where((url) => url.trim().isNotEmpty)
      .toList(growable: false);

  String get displayName => nameCn.trim().isNotEmpty ? nameCn : name;

  factory SubjectWallpaper.fromJson(Map<String, dynamic> json) =>
      SubjectWallpaper(
        subjectId: json['subjectId'] as int,
        name: json['name'] as String? ?? '',
        nameCn: json['nameCn'] as String? ?? '',
        backdrops: (json['backdrops'] as List? ?? const [])
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList(growable: false),
        posters: (json['posters'] as List? ?? const [])
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList(growable: false),
      );
}
