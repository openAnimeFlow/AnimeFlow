class BgmNextApi {
  static const String baseUrl = 'https://next.bgm.tv';

  ///条目
  static const String subjects = '/p1/subjects';

  ///热门条目
  static const String hot = '/p1/trending/subjects';

  ///章节s
  static const String episodes = '/p1/subjects/{subjectId}/episodes';

  ///条目评论
  static const String subjectComments = '/p1/subjects/{subjectId}/comments';

  ///条目搜索
  static const String search = '/p1/search/subjects';

  ///每日放送
  static const String calendar = '/p1/calendar';

  ///剧集评论
  static const String episodeComments = '/p1/episodes/{episodeId}/comments';

  ///角色
  static const String characters = '/p1/subjects/{subjectId}/characters';

  ///关联条目
  static const String relations = '/p1/subjects/{subjectId}/relations';
}

class BgmUsersApi {
  ///条目收藏
  static const String collections = '/p1/collections/subjects';

  ///用户信息
  static const String userInfo = '/p1/users/{username}';

  ///用户收藏
  static const String userCollections = '/p1/users/{username}/collections/subjects';
}

class BgmApi {
  static const String baseUrl = 'https://bgm.tv';

  // 授权
  static const String oauth = '/oauth/authorize';
}
