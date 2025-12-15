class BgmApi {
  static const String nextBaseUrl = 'https://next.bgm.tv';
  //热门条目
  static const String hot = '/p1/trending/subjects';

  //条目
  static const String subjectById = '/p1/subjects/{subjectId}';

  //章节s
  static const String episodes = '/p1/subjects/{subjectId}/episodes';
}