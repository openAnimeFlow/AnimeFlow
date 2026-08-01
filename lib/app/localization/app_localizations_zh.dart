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

  @override
  String get collectionPlanToWatch => '想看';

  @override
  String get collectionWatched => '看过';

  @override
  String get collectionWatching => '在看';

  @override
  String get collectionOnHold => '搁置';

  @override
  String get collectionAbandoned => '抛弃';

  @override
  String get collectionLabel => '收藏';

  @override
  String get searchCollection => '搜索收藏';

  @override
  String get collectionKeywordHint => '输入收藏关键词';

  @override
  String get search => '搜索';

  @override
  String get refreshFailedRetry => '刷新失败，请稍后重试';

  @override
  String get noData => '暂无数据';

  @override
  String get noMore => '没有更多了';

  @override
  String get loginToCollect => '登录后收藏';

  @override
  String get collectionLoadFailed => '加载失败，请稍后重试';

  @override
  String get collectionLoadMoreFailed => '加载更多失败，请稍后重试';

  @override
  String get moreMenu => '更多菜单';

  @override
  String get profileLoadFailed => '获取用户资料失败';

  @override
  String get profileExpired => '用户资料已失效';

  @override
  String get noUserProfile => '暂无用户资料';

  @override
  String get confirmLogout => '确认退出';

  @override
  String get logoutConfirmation => '确定要退出登录吗？';

  @override
  String get logout => '退出登录';

  @override
  String get playbackHistory => '播放记录';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get refreshCurrentTab => '刷新当前标签';

  @override
  String get showUserInfo => '显示用户信息';

  @override
  String get hideUserInfo => '隐藏用户信息';

  @override
  String joinedDate(Object date) {
    return '$date加入';
  }

  @override
  String get userInfoSettings => '用户信息';

  @override
  String get accountSettings => '账户设置';

  @override
  String get appAppearance => '应用与外观';

  @override
  String get themeStyle => '主题样式';

  @override
  String get playbackHistoryVideoSource => '播放历史与视频源';

  @override
  String get sourceManagement => '数据源管理';

  @override
  String get playerSettings => '播放器设置';

  @override
  String get playbackSettings => '播放';

  @override
  String get otherSettings => '其他';

  @override
  String get about => '关于';

  @override
  String get themeMode => '主题模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '深色护眼';

  @override
  String get lightMode => '浅色模式';

  @override
  String get lightModeSubtitle => '明亮清爽';

  @override
  String get followSystem => '跟随系统';

  @override
  String get autoAdapt => '自动适配';

  @override
  String get themeColor => '主题颜色';

  @override
  String get fontStyle => '字体样式';

  @override
  String get customAppFont => '自定义应用字体';

  @override
  String get autoNextEpisode => '自动跳转下一集';

  @override
  String get autoNextEpisodeSubtitle => '播放完成后自动切换到下一集';

  @override
  String get adBlocker => '过滤广告';

  @override
  String get adBlockerSubtitle => '过滤视频中插入的广告切片';

  @override
  String get skipDuration => '跳过时长（秒）';

  @override
  String get skipDurationSubtitle => '用于跳过视频 OP/ED';

  @override
  String get seconds => '秒';

  @override
  String get playbackProgress => '播放进度';

  @override
  String get saveEpisodeProgress => '保存剧集进度';

  @override
  String get saveEpisodeProgressSubtitle => '播放至90%自动保存剧集进度，下次从未观看的剧集开始播放';

  @override
  String get playbackControl => '播放控制';

  @override
  String get longPressFastForwardSpeed => '长按快进速度';
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

  @override
  String get collectionPlanToWatch => '想看';

  @override
  String get collectionWatched => '看过';

  @override
  String get collectionWatching => '在看';

  @override
  String get collectionOnHold => '搁置';

  @override
  String get collectionAbandoned => '抛弃';

  @override
  String get collectionLabel => '收藏';

  @override
  String get searchCollection => '搜索收藏';

  @override
  String get collectionKeywordHint => '输入收藏关键词';

  @override
  String get search => '搜索';

  @override
  String get refreshFailedRetry => '刷新失败，请稍后重试';

  @override
  String get noData => '暂无数据';

  @override
  String get noMore => '没有更多了';

  @override
  String get loginToCollect => '登录后收藏';

  @override
  String get collectionLoadFailed => '加载失败，请稍后重试';

  @override
  String get collectionLoadMoreFailed => '加载更多失败，请稍后重试';

  @override
  String get moreMenu => '更多菜单';

  @override
  String get profileLoadFailed => '获取用户资料失败';

  @override
  String get profileExpired => '用户资料已失效';

  @override
  String get noUserProfile => '暂无用户资料';

  @override
  String get confirmLogout => '确认退出';

  @override
  String get logoutConfirmation => '确定要退出登录吗？';

  @override
  String get logout => '退出登录';

  @override
  String get playbackHistory => '播放记录';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get refreshCurrentTab => '刷新当前标签';

  @override
  String get showUserInfo => '显示用户信息';

  @override
  String get hideUserInfo => '隐藏用户信息';

  @override
  String joinedDate(Object date) {
    return '$date加入';
  }

  @override
  String get userInfoSettings => '用户信息';

  @override
  String get accountSettings => '账户设置';

  @override
  String get appAppearance => '应用与外观';

  @override
  String get themeStyle => '主题样式';

  @override
  String get playbackHistoryVideoSource => '播放历史与视频源';

  @override
  String get sourceManagement => '数据源管理';

  @override
  String get playerSettings => '播放器设置';

  @override
  String get playbackSettings => '播放';

  @override
  String get otherSettings => '其他';

  @override
  String get about => '关于';

  @override
  String get themeMode => '主题模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '深色护眼';

  @override
  String get lightMode => '浅色模式';

  @override
  String get lightModeSubtitle => '明亮清爽';

  @override
  String get followSystem => '跟随系统';

  @override
  String get autoAdapt => '自动适配';

  @override
  String get themeColor => '主题颜色';

  @override
  String get fontStyle => '字体样式';

  @override
  String get customAppFont => '自定义应用字体';

  @override
  String get autoNextEpisode => '自动跳转下一集';

  @override
  String get autoNextEpisodeSubtitle => '播放完成后自动切换到下一集';

  @override
  String get adBlocker => '过滤广告';

  @override
  String get adBlockerSubtitle => '过滤视频中插入的广告切片';

  @override
  String get skipDuration => '跳过时长（秒）';

  @override
  String get skipDurationSubtitle => '用于跳过视频 OP/ED';

  @override
  String get seconds => '秒';

  @override
  String get playbackProgress => '播放进度';

  @override
  String get saveEpisodeProgress => '保存剧集进度';

  @override
  String get saveEpisodeProgressSubtitle => '播放至90%自动保存剧集进度，下次从未观看的剧集开始播放';

  @override
  String get playbackControl => '播放控制';

  @override
  String get longPressFastForwardSpeed => '长按快进速度';
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

  @override
  String get collectionPlanToWatch => '想看';

  @override
  String get collectionWatched => '看過';

  @override
  String get collectionWatching => '在看';

  @override
  String get collectionOnHold => '擱置';

  @override
  String get collectionAbandoned => '拋棄';

  @override
  String get collectionLabel => '收藏';

  @override
  String get searchCollection => '搜尋收藏';

  @override
  String get collectionKeywordHint => '輸入收藏關鍵字';

  @override
  String get search => '搜尋';

  @override
  String get refreshFailedRetry => '重新整理失敗，請稍後再試';

  @override
  String get noData => '暫無資料';

  @override
  String get noMore => '沒有更多了';

  @override
  String get loginToCollect => '登入後收藏';

  @override
  String get collectionLoadFailed => '載入失敗，請稍後再試';

  @override
  String get collectionLoadMoreFailed => '載入更多失敗，請稍後再試';

  @override
  String get moreMenu => '更多選單';

  @override
  String get profileLoadFailed => '取得使用者資料失敗';

  @override
  String get profileExpired => '使用者資料已失效';

  @override
  String get noUserProfile => '暫無使用者資料';

  @override
  String get confirmLogout => '確認登出';

  @override
  String get logoutConfirmation => '確定要登出嗎？';

  @override
  String get logout => '登出';

  @override
  String get playbackHistory => '播放記錄';

  @override
  String get clearSearch => '清除搜尋';

  @override
  String get refreshCurrentTab => '重新整理目前標籤';

  @override
  String get showUserInfo => '顯示使用者資訊';

  @override
  String get hideUserInfo => '隱藏使用者資訊';

  @override
  String joinedDate(Object date) {
    return '$date加入';
  }

  @override
  String get userInfoSettings => '使用者資訊';

  @override
  String get accountSettings => '帳戶設定';

  @override
  String get appAppearance => '應用程式與外觀';

  @override
  String get themeStyle => '主題樣式';

  @override
  String get playbackHistoryVideoSource => '播放記錄與影片來源';

  @override
  String get sourceManagement => '資料來源管理';

  @override
  String get playerSettings => '播放器設定';

  @override
  String get playbackSettings => '播放';

  @override
  String get otherSettings => '其他';

  @override
  String get about => '關於';

  @override
  String get themeMode => '主題模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '深色護眼';

  @override
  String get lightMode => '淺色模式';

  @override
  String get lightModeSubtitle => '明亮清爽';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get autoAdapt => '自動適配';

  @override
  String get themeColor => '主題顏色';

  @override
  String get fontStyle => '字型樣式';

  @override
  String get customAppFont => '自訂應用程式字型';

  @override
  String get autoNextEpisode => '自動跳轉下一集';

  @override
  String get autoNextEpisodeSubtitle => '播放完成後自動切換到下一集';

  @override
  String get adBlocker => '過濾廣告';

  @override
  String get adBlockerSubtitle => '過濾影片中插入的廣告片段';

  @override
  String get skipDuration => '跳過時長（秒）';

  @override
  String get skipDurationSubtitle => '用於跳過影片 OP/ED';

  @override
  String get seconds => '秒';

  @override
  String get playbackProgress => '播放進度';

  @override
  String get saveEpisodeProgress => '儲存劇集進度';

  @override
  String get saveEpisodeProgressSubtitle => '播放至90%自動儲存劇集進度，下次從未觀看的劇集開始播放';

  @override
  String get playbackControl => '播放控制';

  @override
  String get longPressFastForwardSpeed => '長按快進速度';
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

  @override
  String get collectionPlanToWatch => '想看';

  @override
  String get collectionWatched => '看過';

  @override
  String get collectionWatching => '在看';

  @override
  String get collectionOnHold => '擱置';

  @override
  String get collectionAbandoned => '拋棄';

  @override
  String get collectionLabel => '收藏';

  @override
  String get searchCollection => '搜尋收藏';

  @override
  String get collectionKeywordHint => '輸入收藏關鍵字';

  @override
  String get search => '搜尋';

  @override
  String get refreshFailedRetry => '重新整理失敗，請稍後再試';

  @override
  String get noData => '暫無資料';

  @override
  String get noMore => '沒有更多了';

  @override
  String get loginToCollect => '登入後收藏';

  @override
  String get collectionLoadFailed => '載入失敗，請稍後再試';

  @override
  String get collectionLoadMoreFailed => '載入更多失敗，請稍後再試';

  @override
  String get moreMenu => '更多選單';

  @override
  String get profileLoadFailed => '取得使用者資料失敗';

  @override
  String get profileExpired => '使用者資料已失效';

  @override
  String get noUserProfile => '暫無使用者資料';

  @override
  String get confirmLogout => '確認登出';

  @override
  String get logoutConfirmation => '確定要登出嗎？';

  @override
  String get logout => '登出';

  @override
  String get playbackHistory => '播放記錄';

  @override
  String get clearSearch => '清除搜尋';

  @override
  String get refreshCurrentTab => '重新整理目前標籤';

  @override
  String get showUserInfo => '顯示使用者資訊';

  @override
  String get hideUserInfo => '隱藏使用者資訊';

  @override
  String joinedDate(Object date) {
    return '$date加入';
  }

  @override
  String get userInfoSettings => '使用者資訊';

  @override
  String get accountSettings => '帳戶設定';

  @override
  String get appAppearance => '應用程式與外觀';

  @override
  String get themeStyle => '主題樣式';

  @override
  String get playbackHistoryVideoSource => '播放記錄與影片來源';

  @override
  String get sourceManagement => '資料來源管理';

  @override
  String get playerSettings => '播放器設定';

  @override
  String get playbackSettings => '播放';

  @override
  String get otherSettings => '其他';

  @override
  String get about => '關於';

  @override
  String get themeMode => '主題模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '深色護眼';

  @override
  String get lightMode => '淺色模式';

  @override
  String get lightModeSubtitle => '明亮清爽';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get autoAdapt => '自動適配';

  @override
  String get themeColor => '主題顏色';

  @override
  String get fontStyle => '字型樣式';

  @override
  String get customAppFont => '自訂應用程式字型';

  @override
  String get autoNextEpisode => '自動跳轉下一集';

  @override
  String get autoNextEpisodeSubtitle => '播放完成後自動切換到下一集';

  @override
  String get adBlocker => '過濾廣告';

  @override
  String get adBlockerSubtitle => '過濾影片中插入的廣告片段';

  @override
  String get skipDuration => '跳過時長（秒）';

  @override
  String get skipDurationSubtitle => '用於跳過影片 OP/ED';

  @override
  String get seconds => '秒';

  @override
  String get playbackProgress => '播放進度';

  @override
  String get saveEpisodeProgress => '儲存劇集進度';

  @override
  String get saveEpisodeProgressSubtitle => '播放至90%自動儲存劇集進度，下次從未觀看的劇集開始播放';

  @override
  String get playbackControl => '播放控制';

  @override
  String get longPressFastForwardSpeed => '長按快進速度';
}
