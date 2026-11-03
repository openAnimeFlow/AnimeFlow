class Constants {
  ///空image
  static const String notImage =
          'https://wsrv.nl/?url=https://bgm.tv/img/info_only.png',

      ///常规请求头
      userAgentName = 'User-Agent',
      authorization = 'Authorization',

      /// Bangumi ClientId
      bgmClientId = 'bgm5267694605415a325',

      /// bangumi请求头
      bangumiUserAgent =
          'AnimeFlow/{version} (https://github.com/openAnimeFlow/AnimeFlow.git)',

      /// AnimeFlow GitHub地址
      animeFlow = 'https://github.com/openAnimeFlow/AnimeFlow',

      /// AnimeFlow
      animeFlowWebsite = 'https://ligg.top';
}

/// 随机UA列表
const List<String> userAgentList = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.1',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0',
];

/// 随机HTTP请求头accept-language字段列表
const List<String> acceptLanguageList = [
  'zh-CN,zh;q=0.9',
  'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
  'zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6',
];

const Map<int, String> episodesTypeLabels = {
  0: '正篇',
  1: '特别篇',
  2: 'OP',
  3: 'ED',
  4: 'Trailer',
  5: 'MAD',
  6: '其他',
};
