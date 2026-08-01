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

  @override
  String get playIntroTab => '简介';

  @override
  String get playCommentsTab => '吐槽';

  @override
  String get pleaseLogin => '请先登录';

  @override
  String get loginBeforeDanmaku => '请先登录后再发送弹幕';

  @override
  String get tip => '提示';

  @override
  String get danmakuSent => '弹幕发送成功';

  @override
  String get danmakuUnsupported => '当前不支持发送弹幕';

  @override
  String get episodeSelection => '选集';

  @override
  String get switchToList => '切换到列表';

  @override
  String get switchToGrid => '切换到网格';

  @override
  String get fetchingEpisodes => '正在获取剧集...';

  @override
  String get episodeLoadFailed => '剧集获取失败';

  @override
  String get noEpisodeData => '暂无章节数据';

  @override
  String get updatedProgress => '已更新观看进度';

  @override
  String get updateFailed => '更新失败';

  @override
  String commentCount(Object count) {
    return '评论数 $count';
  }

  @override
  String get commentLoadFailed => '评论加载失败';

  @override
  String get defaultSort => '默认';

  @override
  String get newestSort => '最新';

  @override
  String get noComments => '暂无评论';

  @override
  String get commentsAction => '评论';

  @override
  String get danmakuSource => '弹幕源:';

  @override
  String totalDanmaku(Object count) {
    return '总装填($count)条弹幕';
  }

  @override
  String get switchDanmaku => '切换弹幕';

  @override
  String get enterTitle => '请输入标题';

  @override
  String get searchResults => '搜索结果:';

  @override
  String get cancel => '取消';

  @override
  String get submit => '提交';

  @override
  String get noDanmakuEpisodes => '暂无剧集数据';

  @override
  String get close => '关闭';

  @override
  String get videoSource => '数据源';

  @override
  String get autoSelectingResource => '自动选择资源中';

  @override
  String get switchSource => '切换源';

  @override
  String get sourceActions => '数据源操作';

  @override
  String get openPlaybackPage => '浏览器播放页面';

  @override
  String get copySourceLink => '复制数据源链接';

  @override
  String get copied => '已复制';

  @override
  String get sourceLinkCopied => '数据源链接已复制';

  @override
  String lineLabel(Object line) {
    return '线路: $line';
  }

  @override
  String get recommendationsTitle => '相关推荐';

  @override
  String get recommendationLoadFailed => '推荐数据获取失败';

  @override
  String get videoSettingsTitle => '视频设置';

  @override
  String get scheduledOff => '定时关闭';

  @override
  String minutesUnit(Object count) {
    return '$count分钟';
  }

  @override
  String hoursUnit(Object count) {
    return '$count小时';
  }

  @override
  String hoursMinutesUnit(Object hours, Object minutes) {
    return '$hours小时$minutes分钟';
  }

  @override
  String get confirm => '确定';

  @override
  String get moreSettingsBuilding => '更多设置正在施工中...';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get back => '返回';

  @override
  String skipSeconds(Object seconds) {
    return '跳过$seconds秒';
  }

  @override
  String get settings => '设置';

  @override
  String get turnOffDanmaku => '关闭弹幕';

  @override
  String get turnOnDanmaku => '开启弹幕';

  @override
  String get danmakuSettings => '弹幕设置';

  @override
  String get loginToSendDanmaku => '登录后才能发送弹幕';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get nextEpisode => '下一集';

  @override
  String get playbackRate => '倍速';

  @override
  String get sendDanmakuHint => '发送弹幕...';

  @override
  String waitToSendDanmaku(Object seconds) {
    return '请等待$seconds秒后再发…';
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

  @override
  String get playIntroTab => '简介';

  @override
  String get playCommentsTab => '吐槽';

  @override
  String get pleaseLogin => '请先登录';

  @override
  String get loginBeforeDanmaku => '请先登录后再发送弹幕';

  @override
  String get tip => '提示';

  @override
  String get danmakuSent => '弹幕发送成功';

  @override
  String get danmakuUnsupported => '当前不支持发送弹幕';

  @override
  String get episodeSelection => '选集';

  @override
  String get switchToList => '切换到列表';

  @override
  String get switchToGrid => '切换到网格';

  @override
  String get fetchingEpisodes => '正在获取剧集...';

  @override
  String get episodeLoadFailed => '剧集获取失败';

  @override
  String get noEpisodeData => '暂无章节数据';

  @override
  String get updatedProgress => '已更新观看进度';

  @override
  String get updateFailed => '更新失败';

  @override
  String commentCount(Object count) {
    return '评论数 $count';
  }

  @override
  String get commentLoadFailed => '评论加载失败';

  @override
  String get defaultSort => '默认';

  @override
  String get newestSort => '最新';

  @override
  String get noComments => '暂无评论';

  @override
  String get commentsAction => '评论';

  @override
  String get danmakuSource => '弹幕源:';

  @override
  String totalDanmaku(Object count) {
    return '总装填($count)条弹幕';
  }

  @override
  String get switchDanmaku => '切换弹幕';

  @override
  String get enterTitle => '请输入标题';

  @override
  String get searchResults => '搜索结果:';

  @override
  String get cancel => '取消';

  @override
  String get submit => '提交';

  @override
  String get noDanmakuEpisodes => '暂无剧集数据';

  @override
  String get close => '关闭';

  @override
  String get videoSource => '数据源';

  @override
  String get autoSelectingResource => '自动选择资源中';

  @override
  String get switchSource => '切换源';

  @override
  String get sourceActions => '数据源操作';

  @override
  String get openPlaybackPage => '浏览器播放页面';

  @override
  String get copySourceLink => '复制数据源链接';

  @override
  String get copied => '已复制';

  @override
  String get sourceLinkCopied => '数据源链接已复制';

  @override
  String lineLabel(Object line) {
    return '线路: $line';
  }

  @override
  String get recommendationsTitle => '相关推荐';

  @override
  String get recommendationLoadFailed => '推荐数据获取失败';

  @override
  String get videoSettingsTitle => '视频设置';

  @override
  String get scheduledOff => '定时关闭';

  @override
  String minutesUnit(Object count) {
    return '$count分钟';
  }

  @override
  String hoursUnit(Object count) {
    return '$count小时';
  }

  @override
  String hoursMinutesUnit(Object hours, Object minutes) {
    return '$hours小时$minutes分钟';
  }

  @override
  String get confirm => '确定';

  @override
  String get moreSettingsBuilding => '更多设置正在施工中...';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get back => '返回';

  @override
  String skipSeconds(Object seconds) {
    return '跳过$seconds秒';
  }

  @override
  String get settings => '设置';

  @override
  String get turnOffDanmaku => '关闭弹幕';

  @override
  String get turnOnDanmaku => '开启弹幕';

  @override
  String get danmakuSettings => '弹幕设置';

  @override
  String get loginToSendDanmaku => '登录后才能发送弹幕';

  @override
  String get pause => '暂停';

  @override
  String get play => '播放';

  @override
  String get nextEpisode => '下一集';

  @override
  String get playbackRate => '倍速';

  @override
  String get sendDanmakuHint => '发送弹幕...';

  @override
  String waitToSendDanmaku(Object seconds) {
    return '请等待$seconds秒后再发…';
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

  @override
  String get playIntroTab => '簡介';

  @override
  String get playCommentsTab => '評論';

  @override
  String get pleaseLogin => '請先登入';

  @override
  String get loginBeforeDanmaku => '請先登入後再發送彈幕';

  @override
  String get tip => '提示';

  @override
  String get danmakuSent => '彈幕發送成功';

  @override
  String get danmakuUnsupported => '目前不支援發送彈幕';

  @override
  String get episodeSelection => '選集';

  @override
  String get switchToList => '切換至列表';

  @override
  String get switchToGrid => '切換至網格';

  @override
  String get fetchingEpisodes => '正在載入劇集...';

  @override
  String get episodeLoadFailed => '劇集載入失敗';

  @override
  String get noEpisodeData => '暫無劇集資料';

  @override
  String get updatedProgress => '已更新觀看進度';

  @override
  String get updateFailed => '更新失敗';

  @override
  String commentCount(Object count) {
    return '評論數 $count';
  }

  @override
  String get commentLoadFailed => '評論載入失敗';

  @override
  String get defaultSort => '預設';

  @override
  String get newestSort => '最新';

  @override
  String get noComments => '暫無評論';

  @override
  String get commentsAction => '評論';

  @override
  String get danmakuSource => '彈幕來源:';

  @override
  String totalDanmaku(Object count) {
    return '總載入($count)條彈幕';
  }

  @override
  String get switchDanmaku => '切換彈幕';

  @override
  String get enterTitle => '請輸入標題';

  @override
  String get searchResults => '搜尋結果:';

  @override
  String get cancel => '取消';

  @override
  String get submit => '提交';

  @override
  String get noDanmakuEpisodes => '暫無劇集資料';

  @override
  String get close => '關閉';

  @override
  String get videoSource => '資料源';

  @override
  String get autoSelectingResource => '正在自動選擇資源';

  @override
  String get switchSource => '切換來源';

  @override
  String get sourceActions => '資料源操作';

  @override
  String get openPlaybackPage => '在瀏覽器開啟播放頁面';

  @override
  String get copySourceLink => '複製資料源連結';

  @override
  String get copied => '已複製';

  @override
  String get sourceLinkCopied => '資料源連結已複製';

  @override
  String lineLabel(Object line) {
    return '線路: $line';
  }

  @override
  String get recommendationsTitle => '相關推薦';

  @override
  String get recommendationLoadFailed => '推薦資料載入失敗';

  @override
  String get videoSettingsTitle => '影片設定';

  @override
  String get scheduledOff => '定時關閉';

  @override
  String minutesUnit(Object count) {
    return '$count分鐘';
  }

  @override
  String hoursUnit(Object count) {
    return '$count小時';
  }

  @override
  String hoursMinutesUnit(Object hours, Object minutes) {
    return '$hours小時$minutes分鐘';
  }

  @override
  String get confirm => '確定';

  @override
  String get moreSettingsBuilding => '更多設定正在施工中...';

  @override
  String get exitFullscreen => '退出全螢幕';

  @override
  String get back => '返回';

  @override
  String skipSeconds(Object seconds) {
    return '跳過$seconds秒';
  }

  @override
  String get settings => '設定';

  @override
  String get turnOffDanmaku => '關閉彈幕';

  @override
  String get turnOnDanmaku => '開啟彈幕';

  @override
  String get danmakuSettings => '彈幕設定';

  @override
  String get loginToSendDanmaku => '登入後才能發送彈幕';

  @override
  String get pause => '暫停';

  @override
  String get play => '播放';

  @override
  String get nextEpisode => '下一集';

  @override
  String get playbackRate => '倍速';

  @override
  String get sendDanmakuHint => '發送彈幕...';

  @override
  String waitToSendDanmaku(Object seconds) {
    return '請等待$seconds秒後再發…';
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

  @override
  String get playIntroTab => '簡介';

  @override
  String get playCommentsTab => '吐槽';

  @override
  String get pleaseLogin => '請先登入';

  @override
  String get loginBeforeDanmaku => '請先登入後再發送彈幕';

  @override
  String get tip => '提示';

  @override
  String get danmakuSent => '彈幕發送成功';

  @override
  String get danmakuUnsupported => '目前不支援發送彈幕';

  @override
  String get episodeSelection => '選集';

  @override
  String get switchToList => '切換到列表';

  @override
  String get switchToGrid => '切換到網格';

  @override
  String get fetchingEpisodes => '正在取得劇集...';

  @override
  String get episodeLoadFailed => '劇集載入失敗';

  @override
  String get noEpisodeData => '暫無章節資料';

  @override
  String get updatedProgress => '已更新觀看進度';

  @override
  String get updateFailed => '更新失敗';

  @override
  String commentCount(Object count) {
    return '評論數 $count';
  }

  @override
  String get commentLoadFailed => '評論載入失敗';

  @override
  String get defaultSort => '預設';

  @override
  String get newestSort => '最新';

  @override
  String get noComments => '暫無評論';

  @override
  String get commentsAction => '評論';

  @override
  String get danmakuSource => '彈幕來源:';

  @override
  String totalDanmaku(Object count) {
    return '總載入($count)條彈幕';
  }

  @override
  String get switchDanmaku => '切換彈幕';

  @override
  String get enterTitle => '請輸入標題';

  @override
  String get searchResults => '搜尋結果:';

  @override
  String get cancel => '取消';

  @override
  String get submit => '提交';

  @override
  String get noDanmakuEpisodes => '暫無劇集資料';

  @override
  String get close => '關閉';

  @override
  String get videoSource => '資料源';

  @override
  String get autoSelectingResource => '正在自動選擇資源';

  @override
  String get switchSource => '切換來源';

  @override
  String get sourceActions => '資料源操作';

  @override
  String get openPlaybackPage => '在瀏覽器開啟播放頁面';

  @override
  String get copySourceLink => '複製資料源連結';

  @override
  String get copied => '已複製';

  @override
  String get sourceLinkCopied => '資料源連結已複製';

  @override
  String lineLabel(Object line) {
    return '線路: $line';
  }

  @override
  String get recommendationsTitle => '相關推薦';

  @override
  String get recommendationLoadFailed => '推薦資料取得失敗';

  @override
  String get videoSettingsTitle => '影片設定';

  @override
  String get scheduledOff => '定時關閉';

  @override
  String minutesUnit(Object count) {
    return '$count分鐘';
  }

  @override
  String hoursUnit(Object count) {
    return '$count小時';
  }

  @override
  String hoursMinutesUnit(Object hours, Object minutes) {
    return '$hours小時$minutes分鐘';
  }

  @override
  String get confirm => '確定';

  @override
  String get moreSettingsBuilding => '更多設定正在施工中...';

  @override
  String get exitFullscreen => '退出全螢幕';

  @override
  String get back => '返回';

  @override
  String skipSeconds(Object seconds) {
    return '跳過$seconds秒';
  }

  @override
  String get settings => '設定';

  @override
  String get turnOffDanmaku => '關閉彈幕';

  @override
  String get turnOnDanmaku => '開啟彈幕';

  @override
  String get danmakuSettings => '彈幕設定';

  @override
  String get loginToSendDanmaku => '登入後才能發送彈幕';

  @override
  String get pause => '暫停';

  @override
  String get play => '播放';

  @override
  String get nextEpisode => '下一集';

  @override
  String get playbackRate => '倍速';

  @override
  String get sendDanmakuHint => '發送彈幕...';

  @override
  String waitToSendDanmaku(Object seconds) {
    return '請等待$seconds秒後再發…';
  }
}
