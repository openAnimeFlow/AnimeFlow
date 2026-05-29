class BgmNextApi {
  static const String baseUrl = 'https://next.bgm.tv',

      ///条目
      subjects = '/p1/subjects',

      ///热门条目
      hot = '/p1/trending/subjects',

      ///章节s
      episodes = '/p1/subjects/{subjectId}/episodes',

      ///条目评论
      subjectComments = '/p1/subjects/{subjectId}/comments',

      ///条目搜索
      search = '/p1/search/subjects',

      ///每日放送
      calendar = '/p1/calendar',

      ///剧集评论
      episodeComments = '/p1/episodes/{episodeId}/comments',

      ///角色列表
      characters = '/p1/subjects/{subjectId}/characters',

      ///角色信息
      character = '/p1/characters/{characterId}',

      ///角色出演作品
      characterCasts = '/p1/characters/{characterId}/casts',

      ///角色吐槽
      characterComments = '/p1/characters/{characterId}/comments',

      ///关联条目
      relations = '/p1/subjects/{subjectId}/relations',

      ///时间线
      timeline = '/p1/timeline',

      ///条目制作人
      staffs = '/p1/subjects/{subjectId}/staffs/persons';
}

class BgmUsersApi {
  ///获取当前用户信息
  static const String me = '/p1/me',

      ///条目收藏
      collections = '/p1/collections/subjects',

      ///用户收藏
      userCollections = '/p1/users/{username}/collections/subjects',

      ///剧集收藏
      collectionsEpisodes = '/p1/collections/episodes',

      ///用户信息
      userInfo = '/p1/users/{username}';
}

class BgmApi {
  // 授权
  static const String oauth = '/oauth/authorize';
}

class CommonApi {
  static const String bgmTV = 'https://bgm.tv',
      bangumiTV = 'https://bangumi.tv',

      /// bangumi请求头
      bangumiUserAgent =
          'AnimeFlow/{version} (https://github.com/openAnimeFlow/AnimeFlow.git)',

      ///AnimeFLow版本信息
      animeFlowVersion = '/repos/openAnimeFlow/AnimeFlow/releases/latest',

      ///GitHubApi
      githubApi = 'https://api.github.com',

      /// Github镜像
      gitMirror = 'https://ghfast.top/',

      ///jsDelivr cdn
      jsDelivr = 'https://cdn.jsdelivr.net/gh/',

      ///插件仓库
      pluginRepo =
          'https://raw.githubusercontent.com/openAnimeFlow/animeFlow-assets/main/plugins',

      /// 字体仓库
      fontRepo =
          'https://raw.githubusercontent.com/openAnimeFlow/animeFlow-assets/main/fonts-repo',

      /// 图片识别番剧
      traceApi = 'https://api.trace.moe/search';
}

class AnimeFlowApi {
  /// AnimeFlow API Server
  static const String animeFlowApi = 'https://ligg.top',
      animeFlowApiDev = 'http://127.0.0.1:1024',

      /// 申请Token
      token = '/api/oauth/token',

      /// 获取弹幕
      getDanmaku = '/api/v1/danmaku',

      /// 刷新Token
      refreshToken = '/api/oauth/refresh',

      /// Session
      session = '/api/oauth/session',

      /// 回调
      callback = '/api/oauth/callback',

      /// 搜索番剧
      dandanPlaySearch = '/api/v1/danmaku/search',

      /// 番剧详情
      animeDetail = '/api/v1/danmaku/bangumi',

      /// 根据BGM番剧ID获取番剧详情
      animeDetailByBgmId = '/api/v1/danmaku/bangumi/bgmtv',

      /// 弹幕
      danmaku = '/api/v1/danmaku',

      /// 获取热门条目
      hot = '/api/v1/bangumi/trending/subjects',

      ///条目
      subjects = '/api/v1/bangumi/subjects',

      ///章节
      episodes = '/api/v1/bangumi/subjects/{subjectId}/episodes',

      /// 剧集评论
      episodeComments = '/api/v1/bangumi/episodes/{episodeId}/comments',

      ///条目搜索
      bangumiSearch = '/api/v1/bangumi/search/subjects',

      ///角色列表
      characters = '/api/v1/bangumi/subjects/{subjectId}/characters',

      ///条目制作人
      staffs = '/api/v1/bangumi/subjects/{subjectId}/staffs/persons',

      ///条目评论
      subjectComments = '/api/v1/bangumi/subjects/{subjectId}/comments',

      ///角色信息
      character = '/api/v1/bangumi/characters/{characterId}',

      ///角色出演作品
      characterCasts = '/api/v1/bangumi/characters/{characterId}/casts',

      ///角色吐槽
      characterComments = '/api/v1/bangumi/characters/{characterId}/comments',

      ///关联条目
      relations = '/api/v1/bangumi/subjects/{subjectId}/relations',

      /// 每日放送、
      calendar = '/api/v1/bangumi/calendar';
}

class DamakuApi {
  static const String dandanAPIDomain = 'https://api.dandanplay.net',

      /// 获取弹幕
      dandanAPIComment = "/api/v2/comment/",

      /// 检索弹弹番剧元数据
      dandanAPISearch = "/api/v2/search/anime",

      /// 获取弹弹番剧元数据
      dandanAPIInfo = "/api/v2/bangumi/",

      /// 获取弹弹番剧元数据（通过BGM番剧ID）
      dandanAPIInfoByBgmBangumiId = "/api/v2/bangumi/bgmtv/";
}
