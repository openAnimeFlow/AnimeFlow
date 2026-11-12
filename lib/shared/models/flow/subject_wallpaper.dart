class SubjectWallpaper {
  const SubjectWallpaper({
    required this.subjectId,
    required this.name,
    required this.nameCn,
    required this.posters,
    this.backdrops = const [],
    this.favorite,
  });

  final int subjectId;
  final String name;
  final String nameCn;
  final List<String> posters;
  final List<String> backdrops;
  final bool? favorite;

  /// 每张不同的图片作为一个随机候选，忽略空地址。
  List<String> get coverImages => {...backdrops, ...posters}
      .where((url) => url.trim().isNotEmpty)
      .toList(growable: false);

  String get displayName => nameCn.trim().isNotEmpty ? nameCn : name;
}
