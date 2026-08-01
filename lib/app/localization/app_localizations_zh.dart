// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get generalSettingsTitle => '通用设置';

  @override
  String get languageLabel => '语言';

  @override
  String get selectLanguageTooltip => '选择语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChineseTaiwan => '繁體中文（台灣）';

  @override
  String get traditionalChineseHongKong => '繁體中文（香港）';

  @override
  String get englishLanguage => 'English';

  @override
  String get recommendTab => '推荐';

  @override
  String get rankingTab => '排行';

  @override
  String get mineTab => '我的';

  @override
  String get settingsLabel => '设置';

  @override
  String get animeTab => '动漫';

  @override
  String get forumTab => '论坛';

  @override
  String get searchAnimeHint => '搜索动漫番剧...';

  @override
  String get playHistorySection => '播放记录';

  @override
  String get viewMore => '查看更多';

  @override
  String watchedProgress(Object episode, Object progress) {
    return '看到$episode话 $progress';
  }

  @override
  String get popularAnimeTitle => '热门动画';

  @override
  String get loadFailed => '加载失败';

  @override
  String get noMoreContent => '没有更多了';

  @override
  String get reload => '重新加载';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String calendarSummary(Object weekday, Object releases, Object viewers) {
    return '周$weekday上映$releases部,总$viewers人收看';
  }

  @override
  String get noUpdatesToday => '今日无番剧更新';

  @override
  String get forumUnderConstruction => '施工中...';

  @override
  String get rankingTitle => '排行榜';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get all => '全部';

  @override
  String yearSuffix(Object year) {
    return '$year年';
  }

  @override
  String monthSuffix(Object month) {
    return '$month月';
  }

  @override
  String get sortRank => '排名';

  @override
  String get sortTrends => '热门';

  @override
  String get sortCollects => '收藏';

  @override
  String get sortDate => '日期';

  @override
  String get sortTitle => '名称';

  @override
  String get rankingNoData => '暂无数据';

  @override
  String get rankingEnd => '到底了';

  @override
  String rankingLoadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get retry => '重试';

  @override
  String get summaryTitle => '简介';

  @override
  String get tagsTitle => '标签';

  @override
  String get detailsTitle => '详情';

  @override
  String get charactersTitle => '角色';

  @override
  String get viewDetails => '查看详情';

  @override
  String get producersTitle => '制作人';

  @override
  String get relatedTitle => '关联条目';

  @override
  String get commentsTitle => '吐槽';

  @override
  String episodeCount(Object count) {
    return '全$count话';
  }

  @override
  String yourRating(Object rating) {
    return '你的评分:$rating';
  }

  @override
  String ratingCount(Object count) {
    return '($count)人评分';
  }

  @override
  String collectionCount(Object count) {
    return '$count收藏/';
  }

  @override
  String watchingCount(Object count) {
    return '$count再看/';
  }

  @override
  String droppedCount(Object count) {
    return '$count抛弃';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get generalSettingsTitle => '通用设置';

  @override
  String get languageLabel => '语言';

  @override
  String get selectLanguageTooltip => '选择语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChineseTaiwan => '繁體中文（台灣）';

  @override
  String get traditionalChineseHongKong => '繁體中文（香港）';

  @override
  String get englishLanguage => 'English';

  @override
  String get recommendTab => '推荐';

  @override
  String get rankingTab => '排行';

  @override
  String get mineTab => '我的';

  @override
  String get settingsLabel => '设置';

  @override
  String get animeTab => '动漫';

  @override
  String get forumTab => '论坛';

  @override
  String get searchAnimeHint => '搜索动漫番剧...';

  @override
  String get playHistorySection => '播放记录';

  @override
  String get viewMore => '查看更多';

  @override
  String watchedProgress(Object episode, Object progress) {
    return '看到$episode话 $progress';
  }

  @override
  String get popularAnimeTitle => '热门动画';

  @override
  String get loadFailed => '加载失败';

  @override
  String get noMoreContent => '没有更多了';

  @override
  String get reload => '重新加载';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String calendarSummary(Object weekday, Object releases, Object viewers) {
    return '周$weekday上映$releases部,总$viewers人收看';
  }

  @override
  String get noUpdatesToday => '今日无番剧更新';

  @override
  String get forumUnderConstruction => '施工中...';

  @override
  String get rankingTitle => '排行榜';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get all => '全部';

  @override
  String yearSuffix(Object year) {
    return '$year年';
  }

  @override
  String monthSuffix(Object month) {
    return '$month月';
  }

  @override
  String get sortRank => '排名';

  @override
  String get sortTrends => '热门';

  @override
  String get sortCollects => '收藏';

  @override
  String get sortDate => '日期';

  @override
  String get sortTitle => '名称';

  @override
  String get rankingNoData => '暂无数据';

  @override
  String get rankingEnd => '到底了';

  @override
  String rankingLoadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get retry => '重试';

  @override
  String get summaryTitle => '简介';

  @override
  String get tagsTitle => '标签';

  @override
  String get detailsTitle => '详情';

  @override
  String get charactersTitle => '角色';

  @override
  String get viewDetails => '查看详情';

  @override
  String get producersTitle => '制作人';

  @override
  String get relatedTitle => '关联条目';

  @override
  String get commentsTitle => '吐槽';

  @override
  String episodeCount(Object count) {
    return '全$count话';
  }

  @override
  String yourRating(Object rating) {
    return '你的评分:$rating';
  }

  @override
  String ratingCount(Object count) {
    return '($count)人评分';
  }

  @override
  String collectionCount(Object count) {
    return '$count收藏/';
  }

  @override
  String watchingCount(Object count) {
    return '$count再看/';
  }

  @override
  String droppedCount(Object count) {
    return '$count抛弃';
  }
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class AppLocalizationsZhHantHk extends AppLocalizationsZh {
  AppLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String get generalSettingsTitle => '一般設定';

  @override
  String get languageLabel => '語言';

  @override
  String get selectLanguageTooltip => '選擇語言';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get traditionalChineseTaiwan => '繁體中文（台灣）';

  @override
  String get traditionalChineseHongKong => '繁體中文（香港）';

  @override
  String get englishLanguage => 'English';

  @override
  String get recommendTab => '推薦';

  @override
  String get rankingTab => '排行';

  @override
  String get mineTab => '我的';

  @override
  String get settingsLabel => '設定';

  @override
  String get animeTab => '動畫';

  @override
  String get forumTab => '論壇';

  @override
  String get searchAnimeHint => '搜尋動畫番組...';

  @override
  String get playHistorySection => '播放記錄';

  @override
  String get viewMore => '查看更多';

  @override
  String watchedProgress(Object episode, Object progress) {
    return '看到$episode話 $progress';
  }

  @override
  String get popularAnimeTitle => '熱門動畫';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get noMoreContent => '沒有更多了';

  @override
  String get reload => '重新載入';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String calendarSummary(Object weekday, Object releases, Object viewers) {
    return '週$weekday上映$releases部,共$viewers人收看';
  }

  @override
  String get noUpdatesToday => '今日沒有番劇更新';

  @override
  String get forumUnderConstruction => '施工中...';

  @override
  String get rankingTitle => '排行榜';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get all => '全部';

  @override
  String yearSuffix(Object year) {
    return '$year年';
  }

  @override
  String monthSuffix(Object month) {
    return '$month月';
  }

  @override
  String get sortRank => '排名';

  @override
  String get sortTrends => '熱門';

  @override
  String get sortCollects => '收藏';

  @override
  String get sortDate => '日期';

  @override
  String get sortTitle => '名稱';

  @override
  String get rankingNoData => '暫無資料';

  @override
  String get rankingEnd => '到底了';

  @override
  String rankingLoadFailed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get retry => '重試';

  @override
  String get summaryTitle => '簡介';

  @override
  String get tagsTitle => '標籤';

  @override
  String get detailsTitle => '詳情';

  @override
  String get charactersTitle => '角色';

  @override
  String get viewDetails => '查看詳情';

  @override
  String get producersTitle => '製作人';

  @override
  String get relatedTitle => '關聯條目';

  @override
  String get commentsTitle => '評論';

  @override
  String episodeCount(Object count) {
    return '全$count集';
  }

  @override
  String yourRating(Object rating) {
    return '你的評分:$rating';
  }

  @override
  String ratingCount(Object count) {
    return '($count)人評分';
  }

  @override
  String collectionCount(Object count) {
    return '$count收藏/';
  }

  @override
  String watchingCount(Object count) {
    return '$count再看/';
  }

  @override
  String droppedCount(Object count) {
    return '$count放棄';
  }
}

/// The translations for Chinese, as used in Taiwan, using the Han script (`zh_Hant_TW`).
class AppLocalizationsZhHantTw extends AppLocalizationsZh {
  AppLocalizationsZhHantTw() : super('zh_Hant_TW');

  @override
  String get generalSettingsTitle => '一般設定';

  @override
  String get languageLabel => '語言';

  @override
  String get selectLanguageTooltip => '選擇語言';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get traditionalChineseTaiwan => '繁體中文（台灣）';

  @override
  String get traditionalChineseHongKong => '繁體中文（香港）';

  @override
  String get englishLanguage => 'English';

  @override
  String get recommendTab => '推薦';

  @override
  String get rankingTab => '排行';

  @override
  String get mineTab => '我的';

  @override
  String get settingsLabel => '設定';

  @override
  String get animeTab => '動畫';

  @override
  String get forumTab => '論壇';

  @override
  String get searchAnimeHint => '搜尋動畫番劇...';

  @override
  String get playHistorySection => '播放記錄';

  @override
  String get viewMore => '查看更多';

  @override
  String watchedProgress(Object episode, Object progress) {
    return '看到$episode話 $progress';
  }

  @override
  String get popularAnimeTitle => '熱門動畫';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get noMoreContent => '沒有更多了';

  @override
  String get reload => '重新載入';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String calendarSummary(Object weekday, Object releases, Object viewers) {
    return '週$weekday上映$releases部,共$viewers人收看';
  }

  @override
  String get noUpdatesToday => '今日沒有番劇更新';

  @override
  String get forumUnderConstruction => '施工中...';

  @override
  String get rankingTitle => '排行榜';

  @override
  String get allYears => '全部年份';

  @override
  String get allMonths => '全部月份';

  @override
  String get all => '全部';

  @override
  String yearSuffix(Object year) {
    return '$year年';
  }

  @override
  String monthSuffix(Object month) {
    return '$month月';
  }

  @override
  String get sortRank => '排名';

  @override
  String get sortTrends => '熱門';

  @override
  String get sortCollects => '收藏';

  @override
  String get sortDate => '日期';

  @override
  String get sortTitle => '名稱';

  @override
  String get rankingNoData => '暫無資料';

  @override
  String get rankingEnd => '到底了';

  @override
  String rankingLoadFailed(Object error) {
    return '載入失敗: $error';
  }

  @override
  String get retry => '重試';

  @override
  String get summaryTitle => '簡介';

  @override
  String get tagsTitle => '標籤';

  @override
  String get detailsTitle => '詳情';

  @override
  String get charactersTitle => '角色';

  @override
  String get viewDetails => '查看詳情';

  @override
  String get producersTitle => '製作人';

  @override
  String get relatedTitle => '關聯條目';

  @override
  String get commentsTitle => '吐槽';

  @override
  String episodeCount(Object count) {
    return '全$count話';
  }

  @override
  String yourRating(Object rating) {
    return '你的評分:$rating';
  }

  @override
  String ratingCount(Object count) {
    return '($count)人評分';
  }

  @override
  String collectionCount(Object count) {
    return '$count收藏/';
  }

  @override
  String watchingCount(Object count) {
    return '$count再看/';
  }

  @override
  String droppedCount(Object count) {
    return '$count拋棄';
  }
}
