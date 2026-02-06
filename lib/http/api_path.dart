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

  ///角色列表
  static const String characters = '/p1/subjects/{subjectId}/characters';

  ///角色信息
  static const String character = '/p1/characters/{characterId}';

  ///角色出演作品
  static const String characterCasts = '/p1/characters/{characterId}/casts';

  ///角色吐槽
  static const String characterComments = '/p1/characters/{characterId}/comments';

  ///关联条目
  static const String relations = '/p1/subjects/{subjectId}/relations';

  ///时间线
  static const String timeline = '/p1/timeline';

  ///条目制作人
  static const String staffs = '/p1/subjects/{subjectId}/staffs/persons';
}

class BgmUsersApi {

  ///获取当前用户信息
  static const String me = '/p1/me';

  ///条目收藏
  static const String collections = '/p1/collections/subjects';

  ///用户收藏
  static const String userCollections = '/p1/users/{username}/collections/subjects';

  ///剧集收藏
  static const String collectionsEpisodes = '/p1/collections/episodes';

  ///用户信息
  static const String userInfo = '/p1/users/{username}';
}

class BgmApi {
  // 授权
  static const String oauth = '/oauth/authorize';
}

class CommonApi {
  static const String bgmTV = 'https://bgm.tv';

  static const String bangumiTV = 'https://bangumi.tv';

  // bangumi请求头
  static const String bangumiUserAgent =
      'AnimeFlow/{version} (https://github.com/openAnimeFlow/AnimeFlow.git)';

  ///AnimeFLow版本信息
  static const String animeFlowVersion = '/repos/openAnimeFlow/AnimeFlow/releases/latest';

  ///GitHubApi
  static const String githubApi = 'https://api.github.com';

  ///插件仓库
  static const String pluginRepo = 'https://raw.githubusercontent.com/openAnimeFlow/animeFlow-assets/main/plugins';
}

class AnimeFlowApi {
  static const String animeFlowApi = 'http://129.204.224.233:1024';

  static const String token = '/oauth/token';

  static const String refreshToken = '/oauth/refresh';

  static const String session = '/oauth/session';

  static const String callback = '/oauth/callback';
}

class DamakuApi {
  static const String dandanAPIDomain = 'https://api.dandanplay.net';

  /// 获取弹幕
  static const String dandanAPIComment = "/api/v2/comment/";

  /// 检索弹弹番剧元数据
  static const String dandanAPISearch = "/api/v2/search/anime";

  /// 获取弹弹番剧元数据
  static const String dandanAPIInfo = "/api/v2/bangumi/";

  /// 获取弹弹番剧元数据（通过BGM番剧ID）
  static const String dandanAPIInfoByBgmBangumiId = "/api/v2/bangumi/bgmtv/{bgmtvSubjectId}";
}
