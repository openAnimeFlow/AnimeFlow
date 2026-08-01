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
  String get fitAuto => '自動填充';

  @override
  String get fitCrop => '裁切填充';

  @override
  String get fitStretch => '拉伸填充';

  @override
  String get buffering => '正在緩衝...';

  @override
  String get loadFailed => '加载失败';

  @override
  String get updateAvailable => '有版本更新';

  @override
  String get disableAutoUpdate => '取消自動更新';

  @override
  String get updateLater => '稍後更新';

  @override
  String get cancelDownload => '取消下載';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateDownloadHint => '安裝包會在 GitHub 儲存庫中下載，部分地區網路速度較慢，請使用代理改善網路';

  @override
  String get downloading => '正在下載...';

  @override
  String get selectDownloadSource => '請選擇下載地址:';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get latestVersion => '目前已是最新版本';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String updateDownloadFailed(Object error) {
    return '更新下載失敗: $error';
  }

  @override
  String get downloadCancelled => '下載已取消';

  @override
  String get downloadCancelledMessage => '已取消下載';

  @override
  String get downloadComplete => '下載完成';

  @override
  String get packageDownloaded => '安裝包已下載完成';

  @override
  String get openFailed => '開啟失敗';

  @override
  String openFileManagerFailed(Object error) {
    return '無法開啟檔案管理器: $error';
  }

  @override
  String get openPackageFolder => '開啟安裝包資料夾';

  @override
  String get openSourceLicense => '開源協議';

  @override
  String get noLicenseInfo => '暫無授權資訊';

  @override
  String get noMoreContent => '没有更多了';

  @override
  String get reload => '重新加载';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String get back => '返回';

  @override
  String get monday => '週一';

  @override
  String get tuesday => '週二';

  @override
  String get wednesday => '週三';

  @override
  String get thursday => '週四';

  @override
  String get friday => '週五';

  @override
  String get saturday => '週六';

  @override
  String get sunday => '週日';

  @override
  String releaseCount(Object count) {
    return '$count 部';
  }

  @override
  String noUpdatesOnWeekday(Object weekday) {
    return '$weekday無番劇更新';
  }

  @override
  String get animeCount => '番劇數量';

  @override
  String get totalWatchers => '總觀看人數';

  @override
  String get averageRating => '平均評分';

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
  String get charactersLoadFailed => '載入角色資訊失敗';

  @override
  String get noCharacters => '暫無角色資訊';

  @override
  String get characterWorks => '出演作品';

  @override
  String get backToTop => '返回頂部';

  @override
  String get noComments => '暫無吐槽';

  @override
  String get characterWorksLoadFailed => '載入出演作品失敗';

  @override
  String get noCharacterWorks => '暫無出演作品';

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
  String get confirmAllWatched => '確認全部看過';

  @override
  String get confirmAllWatchedMessage => '確定要將此番劇的全部劇集標記為看過嗎？';

  @override
  String get markAllWatchedSuccess => '已將全部劇集標記為看過';

  @override
  String loadedEpisodes(Object count) {
    return '已載入 $count 集';
  }

  @override
  String get allWatched => '全部看過';

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
  String get imageSearch => '圖片搜尋';

  @override
  String get switchToUploadImage => '改為上傳圖片檔案';

  @override
  String get switchToImageUrl => '改為輸入圖片 URL';

  @override
  String get searching => '搜尋中...';

  @override
  String get startSearch => '開始搜尋';

  @override
  String get tapToSelectImage => '點選選擇圖片';

  @override
  String get supportedImageFormats => '支援 JPG、PNG、WEBP 格式';

  @override
  String get imagePreviewFailed => '圖片預覽失敗';

  @override
  String get imageSelected => '已選擇圖片';

  @override
  String get tapToReselectImage => '點選可重新選擇圖片';

  @override
  String get reselect => '重新選擇';

  @override
  String get enterImageUrl => '請輸入圖片連結';

  @override
  String get clear => '清除';

  @override
  String get enterImageUrlToPreview => '輸入圖片連結後預覽';

  @override
  String get imageLoadFailed => '圖片載入失敗';

  @override
  String get checkImageUrl => '請檢查連結是否有效';

  @override
  String get recognizingImage => '正在辨識圖片';

  @override
  String get matchingAnimeFromImage => '請稍候，正在從截圖中匹配番劇資訊';

  @override
  String get imageSearchResultPlaceholder => '搜尋結果將在這裡顯示';

  @override
  String get noImageSearchResults => '未取得搜尋結果';

  @override
  String get startImageSearchHint => '選擇圖片檔案或輸入圖片連結後開始搜尋';

  @override
  String get recognitionResults => '辨識結果';

  @override
  String get originalAspectRatioTip => '僅支援使用原始比例番劇截圖搜尋結果';

  @override
  String get clearScreenshotTip => '截圖應清晰，避免過度壓縮或新增浮水印';

  @override
  String get searchEnginePoweredBy => '搜尋引擎由 ';

  @override
  String get providesSupport => ' 提供支援';

  @override
  String get searchAnimeByImage => '以圖搜番';

  @override
  String get searchSuggestions => '搜尋建議';

  @override
  String searchResultCount(Object count) {
    return '搜尋到 $count 筆內容';
  }

  @override
  String get enterKeywordToSearch => '輸入關鍵字開始搜尋';

  @override
  String get searchHistory => '搜尋記錄';

  @override
  String get clearAll => '全部清除';

  @override
  String get delete => '刪除';

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

  @override
  String get danmakuDisplayType => '弹幕显示类型';

  @override
  String get scrollingDanmaku => '滚动弹幕';

  @override
  String get topDanmaku => '顶部弹幕';

  @override
  String get bottomDanmaku => '底部弹幕';

  @override
  String get danmakuSourcePlatform => '弹幕来源平台';

  @override
  String get danmakuStyle => '弹幕样式';

  @override
  String get showBorder => '显示边框';

  @override
  String get showColor => '显示颜色';

  @override
  String get massiveMode => '密集模式';

  @override
  String get danmakuSpeedTitle => '弹幕速度';

  @override
  String danmakuSpeed(Object percent) {
    return '速度：$percent%';
  }

  @override
  String get opacity => '透明度';

  @override
  String get fontSize => '字体大小';

  @override
  String get displayArea => '显示区域';

  @override
  String get logoutSuccess => '已退出登录';

  @override
  String get openAuthorizationFailed => '打开授权页面失败';

  @override
  String get loginStateLoadFailed => '加载登录状态失败';

  @override
  String get notLoggedIn => '尚未登录';

  @override
  String get loginToManageAccount => '登录后可管理账户信息、绑定 Bangumi 账号';

  @override
  String get login => '登录';

  @override
  String get error => '錯誤';

  @override
  String get moreActions => '更多操作';

  @override
  String get unableOpenLink => '無法開啟連結';

  @override
  String get websiteLinkCopied => '網站連結已複製到剪貼簿';

  @override
  String saveImageFailed(Object error) {
    return '儲存圖片失敗: $error';
  }

  @override
  String get openInBrowser => '在瀏覽器中查看';

  @override
  String get downloadCover => '下載封面';

  @override
  String get copyWebsite => '複製網站連結';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get welcomeTo => '歡迎來到 ';

  @override
  String get loginToManageCollection => '登入後管理收藏';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get enterEmail => '請輸入電子郵件';

  @override
  String get invalidEmail => '請輸入有效的電子郵件';

  @override
  String get enterPassword => '請輸入密碼';

  @override
  String get passwordMinLength => '密碼至少需要 6 位';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get forgotPassword => '忘記密碼';

  @override
  String get loggingIn => '登入中...';

  @override
  String get bangumiAuthorizeLogin => 'Bangumi 授權登入';

  @override
  String get bangumi => 'Bangumi';

  @override
  String get noAccount => '還沒有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get authorizeLogin => '授权登录';

  @override
  String get registerAccount => '注册账号';

  @override
  String get registerSuccess => '註冊成功';

  @override
  String get registerTitle => '註冊';

  @override
  String get createAccount => '建立帳號';

  @override
  String get registerSubtitle => '加入 AnimeFlow，同步你的追番體驗';

  @override
  String get enterGraphicCaptcha => '請先填寫圖形驗證碼';

  @override
  String get emailCodeSent => '驗證碼已寄出，請查收電子郵件';

  @override
  String get invalidEmailFormat => '電子郵件格式不正確';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get passwordLengthRange => '密碼長度需在 6-30 位之間';

  @override
  String get enterConfirmPassword => '請再次輸入密碼';

  @override
  String get passwordMismatch => '兩次輸入的密碼不一致';

  @override
  String get emailVerificationCode => '電子郵件驗證碼';

  @override
  String get enterEmailCode => '請輸入電子郵件驗證碼';

  @override
  String get emailCodeLength => '驗證碼必須為 6 位數字';

  @override
  String get haveAccountBackToLogin => '已有帳號？返回登入';

  @override
  String get accountInfo => '账户信息';

  @override
  String get thirdPartyAccounts => '第三方账号';

  @override
  String get accountActions => '账户操作';

  @override
  String get nicknameUpdated => '昵称已更新';

  @override
  String get waitingBangumiAuthorization => '正在等待 Bangumi 授权结果...';

  @override
  String get authorizing => '授权中...';

  @override
  String get bound => '已绑定';

  @override
  String get unbound => '未绑定';

  @override
  String get loading => '加载中...';

  @override
  String get bindStatusLoadFailed => '获取绑定状态失败';

  @override
  String get bindBangumiHint => '绑定 Bangumi 账号后可同步收藏等数据';

  @override
  String get bindBangumiAccount => '绑定 Bangumi 账号';

  @override
  String get confirmUnbind => '确认解绑';

  @override
  String get unbindConfirmation => '确定要解绑 Bangumi 账号吗？解绑后可能影响部分功能。';

  @override
  String get confirmUnbindAction => '确定解绑';

  @override
  String get unbind => '解绑';

  @override
  String get bangumiBindSuccessHint => 'Bangumi 授权与绑定应可正常使用。';

  @override
  String get bangumiBindFailureHint => '授权或绑定 Bangumi 时，建议开启 VPN 或代理后重试。';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get autoUpdate => '自动更新';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get openSource => '开源地址';

  @override
  String get unableOpenWeb => '无法打开网页';

  @override
  String get deviceUnsupportedWeb => '你的设备可能不支持此功能';

  @override
  String get thanks => '鸣谢';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get specialThanks => '特别鸣谢';

  @override
  String get thanksDescription => '感谢以下优秀的开源项目和技术支持，让 AnimeFlow 变得更好';

  @override
  String get kazumiWebViewSupport => 'Kazumi 项目提供的 WebView 技术支持';

  @override
  String get mediaKitDescription => '跨平台视频播放器，支持高质量视频播放';

  @override
  String get canvasDanmakuDescription => '弹幕插件，提供流畅的弹幕绘制';

  @override
  String get dandanplayDescription => '提供丰富的弹幕数据源';

  @override
  String get bangumiDescription => '提供番剧信息和用户数据同步服务';

  @override
  String get anime4kDescription => '超分辨率技术，提升视频画质';

  @override
  String get traceMoeDescription => '提供以图识别番功能';

  @override
  String fontRefreshFailed(Object error) {
    return '刷新失败：$error';
  }

  @override
  String get fontStylePageTitle => '字体样式';

  @override
  String get refreshFontList => '刷新字体列表';

  @override
  String get fontLibrary => '字体库';

  @override
  String get cdnAcceleration => 'CDN 加速';

  @override
  String get fontDelayHint => '新上架的字体可能会延迟显示';

  @override
  String get cdnTooltip => '开启：经 jsDelivr 拉取字体；关闭：直连 GitHub Raw（走镜像）';

  @override
  String get fontRestartHint => '如果字体效果没有完全显示请重启应用';

  @override
  String get noOtherFonts => '暂无其他可用字体';

  @override
  String get downloadedOrphanFonts => '本地已下载（远程已下架）';

  @override
  String get orphanFontDescription =>
      '以下字体不再出现在远程仓库，但本地仍保留有字体文件。可在此处直接删除或继续应用。';

  @override
  String get fontListLoadFailed => '加载字体列表失败';

  @override
  String get systemFont => '跟随系统';

  @override
  String get systemFontSubtitle => '使用系统默认字体';

  @override
  String fontAuthorInfo(Object author, Object size) {
    return '作者：$author - 字体包体积：$size';
  }

  @override
  String get downloadFont => '下载字体';

  @override
  String get appliedFont => '已应用，点击取消使用';

  @override
  String get applyFont => '点击应用此字体';

  @override
  String get deleteDownloadedFont => '删除已下载字体';

  @override
  String get downloadFontFailedRetry => '下载失败，点击重试';

  @override
  String get deleteFont => '删除字体';

  @override
  String deleteSelectedFontConfirmation(Object fontName) {
    return '将删除「$fontName」的本地文件，并恢复为系统字体，确定继续？';
  }

  @override
  String deleteFontConfirmation(Object fontName) {
    return '确定删除「$fontName」的本地字体文件？';
  }

  @override
  String get previewLoadFailed => '预览加载失败';

  @override
  String get fontPreviewHeadline => '欢迎使用 AnimeFlow';

  @override
  String get orphanFontAvailable => '远程仓库已下架，仍可继续使用本地字体';

  @override
  String get orphanFontMissing => '本地字体文件已丢失，可在此处清理记录';

  @override
  String get confirmDelete => '确认删除';

  @override
  String deleteSourceConfirmation(Object name) {
    return '确定要删除数据源 \"$name\" 吗？此操作不可恢复。';
  }

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get deleteFailed => '删除失败';

  @override
  String sourceDeleted(Object name) {
    return '数据源 \"$name\" 已被删除';
  }

  @override
  String sourceDeleteFailed(Object error, Object name) {
    return '删除数据源 \"$name\" 时发生错误：$error';
  }

  @override
  String get downloadConfig => '下载配置';

  @override
  String get addSource => '添加数据源';

  @override
  String get editSource => '编辑数据源';

  @override
  String get saveFailed => '保存失败';

  @override
  String dataSaveFailed(Object error) {
    return '数据保存失败：$error';
  }

  @override
  String get fieldRequired => '此字段不能为空';

  @override
  String get versionNumber => '版本号';

  @override
  String get versionExample => '如（1.0.0）';

  @override
  String get sourceName => '名称';

  @override
  String get sourceNameHint => '网站名称，唯一值避免与其他配置名称重复，否则将被覆盖';

  @override
  String get iconLink => '图标链接';

  @override
  String get websiteLink => '网站链接';

  @override
  String get websiteLinkHint => '网站主链接，避免以 / 结尾';

  @override
  String get searchLink => '搜索链接';

  @override
  String searchLinkHint(Object keyword) {
    return '用$keyword搜索关键字，示例：https://dm.xifanacg.com/search.html?wd=$keyword';
  }

  @override
  String get searchContentList => '搜索内容列表';

  @override
  String get searchListName => '搜索列表名称';

  @override
  String get searchListLink => '搜索列表链接';

  @override
  String get lineName => '线路名称';

  @override
  String get episodeList => '剧集列表';

  @override
  String get episode => '剧集';

  @override
  String get episodeHint => '剧集链接，从剧集列表中获取的数据的 XPath';

  @override
  String get antiCrawlerOptional => '反爬 / 验证码（可选）';

  @override
  String get enableWebViewCaptcha => '启用 WebView 验证码处理';

  @override
  String get webViewCaptchaSubtitle => '搜索触发验证码时，用 WebView 完成验证并保存 Cookie';

  @override
  String get captchaType => '验证类型';

  @override
  String get imageCaptchaManual => '图片验证码（手动输入）';

  @override
  String get autoClickCaptcha => '自动点击验证按钮';

  @override
  String get captchaImageXPath => '验证码图片 XPath';

  @override
  String get captchaImageXPathHint => 'WebView 内定位验证码图片元素';

  @override
  String get captchaInputXPath => '验证码输入框 XPath';

  @override
  String get captchaInputXPathHint => '供用户输入验证码的 input 元素';

  @override
  String get submitCaptchaXPath => '提交验证码按钮 XPath';

  @override
  String get verifyButtonXPath => '验证按钮 XPath';

  @override
  String get submitCaptchaHint => '点击后提交验证码的按钮';

  @override
  String get autoClickCaptchaHint => '检测到后自动点击的验证按钮（如「我不是机器人」）';

  @override
  String get downloadSuccess => '下载成功';

  @override
  String pluginDownloaded(Object name) {
    return '插件 \"$name\" 已下载';
  }

  @override
  String pluginDownloadFailed(Object error, Object name) {
    return '下载插件 \"$name\" 时发生错误：$error';
  }

  @override
  String get updateSuccess => '更新成功';

  @override
  String pluginUpdated(Object name, Object version) {
    return '插件 \"$name\" 已更新到版本 $version';
  }

  @override
  String pluginUpdateFailed(Object error, Object name) {
    return '更新插件 \"$name\" 时发生错误：$error';
  }

  @override
  String get downloadSources => '下载数据源';

  @override
  String get downloadSourcesSubtitle => '当前会从 GitHub 仓库中下载数据源，注意网络环境，下拉刷新数据';

  @override
  String get useMirror => '使用镜像';

  @override
  String get useMirrorSubtitle => '无法直连 GitHub 时开启，通过镜像拉取插件列表';

  @override
  String get noDataRefresh => '没有找到数据，请刷新';

  @override
  String get downloaded => '已下载';

  @override
  String get updating => '更新中…';

  @override
  String get update => '更新';

  @override
  String pluginVersionDate(Object date, Object version) {
    return '版本：$version - $date';
  }

  @override
  String get collectionSyncTitle => '收藏同步';

  @override
  String get collectionSyncStarted => '收藏同步已開始';

  @override
  String get syncStartFailed => '啟動同步失敗';

  @override
  String get refreshStatus => '重新整理狀態';

  @override
  String get refreshStatusFailed => '重新整理狀態失敗';

  @override
  String syncedItems(Object count) {
    return '已同步 $count 條';
  }

  @override
  String get syncInProgress => '同步進行中…';

  @override
  String get syncBangumiCollection => '同步 Bangumi 收藏';

  @override
  String get syncStatusLoadFailed => '取得同步狀態失敗';

  @override
  String get syncStatusIdle => '未同步';

  @override
  String get syncStatusRunning => '同步中';

  @override
  String get syncStatusSuccess => '同步完成';

  @override
  String get syncStatusFailed => '同步失敗';

  @override
  String get introduction => '介紹';

  @override
  String get collection => '收藏';

  @override
  String get timeline => '時間軸';

  @override
  String get userInfoUnavailable => '無法取得使用者資訊';

  @override
  String get timelineComingSoon => '時間軸功能即將推出';

  @override
  String get statistics => '統計';

  @override
  String get bio => '個人簡介';

  @override
  String get location => '所在地';

  @override
  String get website => '網站';

  @override
  String get mysteriousUser => '這位使用者很神秘';

  @override
  String get manualSearch => '手動搜尋';

  @override
  String get manualSearchResource => '手動搜尋資源';

  @override
  String fetchingResource(Object website) {
    return '正在取得 $website 的資源';
  }

  @override
  String get reSearchingResource => '目前網站正在重新搜尋，請稍候片刻。';

  @override
  String resourceRequestFailed(Object website) {
    return '$website 請求失敗';
  }

  @override
  String resourceNotFoundForSite(Object website) {
    return '$website 暫未搜尋到資源';
  }

  @override
  String get noPlayableSourceHint => '沒有搜尋到可用播放來源。你可以稍後重試，或切換其他網站。';

  @override
  String get searchAgain => '重新搜尋';

  @override
  String get unnamedLine => '未命名線路';

  @override
  String get descending => '降冪';

  @override
  String get ascending => '升冪';

  @override
  String get lineFilter => '線路篩選';

  @override
  String get allLines => '全部線路';

  @override
  String currentEpisodeCount(Object count) {
    return '目前集數($count)';
  }

  @override
  String allEpisodesCount(Object count) {
    return '全集($count)';
  }

  @override
  String get noPlayableSourceForEpisode => '目前劇集沒有可用播放來源';

  @override
  String get episodeNotInResultsHint =>
      '目前選取的劇集不在這些結果中。你可以切換到「全部集數」手動指定資源網站集數。';

  @override
  String get episodeNoSourceHint => '目前劇集沒有找到相符的播放來源。';

  @override
  String get noSelectableEpisodes => '沒有可選集數';

  @override
  String get siteNoEpisodes => '目前網站沒有回傳可用播放集數。';

  @override
  String videoSourceLoadFailed(Object error) {
    return '取得影片來源失敗：$error';
  }

  @override
  String get matchLabel => '相符度：';

  @override
  String get verificationSuccess => '驗證成功';

  @override
  String get verificationRetrying => '正在重新搜尋，請稍候…';

  @override
  String get enterCaptcha => '請輸入驗證碼';

  @override
  String get captchaMayBeWrong => '驗證碼可能有誤，請重新輸入';

  @override
  String siteRequiresCaptcha(Object website) {
    return '$website 需要驗證碼驗證';
  }

  @override
  String get verify => '進行驗證';

  @override
  String siteAutoVerifying(Object website) {
    return '$website 正在自動完成驗證，請稍候';
  }

  @override
  String captchaVerification(Object website) {
    return '$website 驗證碼驗證';
  }

  @override
  String get loadingCaptchaImage => '正在載入驗證碼圖片…';

  @override
  String get imageDecodeFailed => '圖片解碼失敗';

  @override
  String episodeNumber(Object episode) {
    return '第$episode集';
  }

  @override
  String watchedLabel(Object progress) {
    return '觀看$progress';
  }

  @override
  String playEpisode(Object episode) {
    return '播放（$episode）';
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
  String get fitAuto => '自动填充';

  @override
  String get fitCrop => '裁剪填充';

  @override
  String get fitStretch => '拉伸填充';

  @override
  String get buffering => '正在缓冲...';

  @override
  String get loadFailed => '加载失败';

  @override
  String get updateAvailable => '有版本更新';

  @override
  String get disableAutoUpdate => '取消自动更新';

  @override
  String get updateLater => '稍后更新';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateDownloadHint => '安装包会在 GitHub 仓库中下载，国内网络速度较慢，请使用代理改善网络';

  @override
  String get downloading => '正在下载...';

  @override
  String get selectDownloadSource => '请选择下载地址:';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get latestVersion => '当前为最新版本';

  @override
  String get downloadFailed => '下载失败';

  @override
  String updateDownloadFailed(Object error) {
    return '更新下载失败: $error';
  }

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get downloadCancelledMessage => '已取消下载';

  @override
  String get downloadComplete => '下载完成';

  @override
  String get packageDownloaded => '安装包已下载完成';

  @override
  String get openFailed => '打开失败';

  @override
  String openFileManagerFailed(Object error) {
    return '无法打开文件管理器: $error';
  }

  @override
  String get openPackageFolder => '打开安装包文件夹';

  @override
  String get openSourceLicense => '开源协议';

  @override
  String get noLicenseInfo => '暂无许可证信息';

  @override
  String get noMoreContent => '没有更多了';

  @override
  String get reload => '重新加载';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String get back => '返回';

  @override
  String get monday => '周一';

  @override
  String get tuesday => '周二';

  @override
  String get wednesday => '周三';

  @override
  String get thursday => '周四';

  @override
  String get friday => '周五';

  @override
  String get saturday => '周六';

  @override
  String get sunday => '周日';

  @override
  String releaseCount(Object count) {
    return '$count部';
  }

  @override
  String noUpdatesOnWeekday(Object weekday) {
    return '$weekday无番剧更新';
  }

  @override
  String get animeCount => '番剧数量';

  @override
  String get totalWatchers => '总观看人数';

  @override
  String get averageRating => '平均评分';

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
  String get charactersLoadFailed => '加载角色信息失败';

  @override
  String get noCharacters => '暂无角色信息';

  @override
  String get characterWorks => '出演';

  @override
  String get backToTop => '返回顶部';

  @override
  String get noComments => '暂无吐槽';

  @override
  String get characterWorksLoadFailed => '加载出演作品失败';

  @override
  String get noCharacterWorks => '暂无出演作品';

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
  String get confirmAllWatched => '确认全部已看';

  @override
  String get confirmAllWatchedMessage => '确定将该番剧的全部剧集标记为已看吗？';

  @override
  String get markAllWatchedSuccess => '已将全部剧集标记为已看';

  @override
  String loadedEpisodes(Object count) {
    return '已加载 $count 集';
  }

  @override
  String get allWatched => '全部已看';

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
  String get imageSearch => '图片搜索';

  @override
  String get switchToUploadImage => '改为上传图片文件';

  @override
  String get switchToImageUrl => '改为输入图片 URL';

  @override
  String get searching => '搜索中...';

  @override
  String get startSearch => '开始搜索';

  @override
  String get tapToSelectImage => '点击选择图片';

  @override
  String get supportedImageFormats => '支持 JPG、PNG、WEBP 格式';

  @override
  String get imagePreviewFailed => '图片预览失败';

  @override
  String get imageSelected => '已选择图片';

  @override
  String get tapToReselectImage => '点击可重新选择图片';

  @override
  String get reselect => '重新选择';

  @override
  String get enterImageUrl => '请输入图片链接';

  @override
  String get clear => '清除';

  @override
  String get enterImageUrlToPreview => '输入图片链接后预览';

  @override
  String get imageLoadFailed => '图片加载失败';

  @override
  String get checkImageUrl => '请检查链接是否有效';

  @override
  String get recognizingImage => '正在识别图片';

  @override
  String get matchingAnimeFromImage => '请稍候，正在从截图中匹配番剧信息';

  @override
  String get imageSearchResultPlaceholder => '搜索结果将在这里展示';

  @override
  String get noImageSearchResults => '未获取到搜索结果';

  @override
  String get startImageSearchHint => '选择图片文件或输入图片链接后开始搜索';

  @override
  String get recognitionResults => '识别结果';

  @override
  String get originalAspectRatioTip => '仅支持使用原始比例番剧截图搜索结果';

  @override
  String get clearScreenshotTip => '截图应清晰，避免过度压缩或添加水印';

  @override
  String get searchEnginePoweredBy => '搜索引擎由 ';

  @override
  String get providesSupport => ' 提供支持';

  @override
  String get searchAnimeByImage => '以图搜番';

  @override
  String get searchSuggestions => '搜索建议';

  @override
  String searchResultCount(Object count) {
    return '搜索到 $count 条内容';
  }

  @override
  String get enterKeywordToSearch => '输入关键词开始搜索';

  @override
  String get searchHistory => '搜索历史';

  @override
  String get clearAll => '清除全部';

  @override
  String get delete => '删除';

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

  @override
  String get danmakuDisplayType => '弹幕显示类型';

  @override
  String get scrollingDanmaku => '滚动弹幕';

  @override
  String get topDanmaku => '顶部弹幕';

  @override
  String get bottomDanmaku => '底部弹幕';

  @override
  String get danmakuSourcePlatform => '弹幕来源平台';

  @override
  String get danmakuStyle => '弹幕样式';

  @override
  String get showBorder => '显示边框';

  @override
  String get showColor => '显示颜色';

  @override
  String get massiveMode => '密集模式';

  @override
  String get danmakuSpeedTitle => '弹幕速度';

  @override
  String danmakuSpeed(Object percent) {
    return '速度：$percent%';
  }

  @override
  String get opacity => '透明度';

  @override
  String get fontSize => '字体大小';

  @override
  String get displayArea => '显示区域';

  @override
  String get logoutSuccess => '已退出登录';

  @override
  String get openAuthorizationFailed => '打开授权页面失败';

  @override
  String get loginStateLoadFailed => '加载登录状态失败';

  @override
  String get notLoggedIn => '尚未登录';

  @override
  String get loginToManageAccount => '登录后可管理账户信息、绑定 Bangumi 账号';

  @override
  String get login => '登录';

  @override
  String get error => '错误';

  @override
  String get moreActions => '更多操作';

  @override
  String get unableOpenLink => '无法打开链接';

  @override
  String get websiteLinkCopied => '网站链接已复制到剪贴板';

  @override
  String saveImageFailed(Object error) {
    return '保存图片失败: $error';
  }

  @override
  String get openInBrowser => '浏览器查看';

  @override
  String get downloadCover => '下载封面';

  @override
  String get copyWebsite => '复制网站';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get welcomeTo => '欢迎来到 ';

  @override
  String get loginToManageCollection => '登录后进行收藏管理';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get enterEmail => '请输入邮箱';

  @override
  String get invalidEmail => '请输入有效邮箱';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get passwordMinLength => '密码至少需要 6 位';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get loggingIn => '登录中...';

  @override
  String get bangumiAuthorizeLogin => 'Bangumi 授权登录';

  @override
  String get bangumi => 'Bangumi';

  @override
  String get noAccount => '还没有账号？';

  @override
  String get registerNow => '立即注册';

  @override
  String get authorizeLogin => '授权登录';

  @override
  String get registerAccount => '注册账号';

  @override
  String get registerSuccess => '注册成功';

  @override
  String get registerTitle => '注册';

  @override
  String get createAccount => '创建账号';

  @override
  String get registerSubtitle => '加入 AnimeFlow，同步你的追番体验';

  @override
  String get enterGraphicCaptcha => '请先填写图形验证码';

  @override
  String get emailCodeSent => '验证码已发送，请查收邮件';

  @override
  String get invalidEmailFormat => '邮箱格式不正确';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordLengthRange => '密码长度需在 6-30 位之间';

  @override
  String get enterConfirmPassword => '请再次输入密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致';

  @override
  String get emailVerificationCode => '邮箱验证码';

  @override
  String get enterEmailCode => '请输入邮箱验证码';

  @override
  String get emailCodeLength => '验证码为 6 位数字';

  @override
  String get haveAccountBackToLogin => '已有账号？返回登录';

  @override
  String get accountInfo => '账户信息';

  @override
  String get thirdPartyAccounts => '第三方账号';

  @override
  String get accountActions => '账户操作';

  @override
  String get nicknameUpdated => '昵称已更新';

  @override
  String get waitingBangumiAuthorization => '正在等待 Bangumi 授权结果...';

  @override
  String get authorizing => '授权中...';

  @override
  String get bound => '已绑定';

  @override
  String get unbound => '未绑定';

  @override
  String get loading => '加载中...';

  @override
  String get bindStatusLoadFailed => '获取绑定状态失败';

  @override
  String get bindBangumiHint => '绑定 Bangumi 账号后可同步收藏等数据';

  @override
  String get bindBangumiAccount => '绑定 Bangumi 账号';

  @override
  String get confirmUnbind => '确认解绑';

  @override
  String get unbindConfirmation => '确定要解绑 Bangumi 账号吗？解绑后可能影响部分功能。';

  @override
  String get confirmUnbindAction => '确定解绑';

  @override
  String get unbind => '解绑';

  @override
  String get bangumiBindSuccessHint => 'Bangumi 授权与绑定应可正常使用。';

  @override
  String get bangumiBindFailureHint => '授权或绑定 Bangumi 时，建议开启 VPN 或代理后重试。';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get autoUpdate => '自动更新';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get openSource => '开源地址';

  @override
  String get unableOpenWeb => '无法打开网页';

  @override
  String get deviceUnsupportedWeb => '你的设备可能不支持此功能';

  @override
  String get thanks => '鸣谢';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get specialThanks => '特别鸣谢';

  @override
  String get thanksDescription => '感谢以下优秀的开源项目和技术支持，让 AnimeFlow 变得更好';

  @override
  String get kazumiWebViewSupport => 'Kazumi 项目提供的 WebView 技术支持';

  @override
  String get mediaKitDescription => '跨平台视频播放器，支持高质量视频播放';

  @override
  String get canvasDanmakuDescription => '弹幕插件，提供流畅的弹幕绘制';

  @override
  String get dandanplayDescription => '提供丰富的弹幕数据源';

  @override
  String get bangumiDescription => '提供番剧信息和用户数据同步服务';

  @override
  String get anime4kDescription => '超分辨率技术，提升视频画质';

  @override
  String get traceMoeDescription => '提供以图识别番功能';

  @override
  String fontRefreshFailed(Object error) {
    return '刷新失败：$error';
  }

  @override
  String get fontStylePageTitle => '字体样式';

  @override
  String get refreshFontList => '刷新字体列表';

  @override
  String get fontLibrary => '字体库';

  @override
  String get cdnAcceleration => 'CDN 加速';

  @override
  String get fontDelayHint => '新上架的字体可能会延迟显示';

  @override
  String get cdnTooltip => '开启：经 jsDelivr 拉取字体；关闭：直连 GitHub Raw（走镜像）';

  @override
  String get fontRestartHint => '如果字体效果没有完全显示请重启应用';

  @override
  String get noOtherFonts => '暂无其他可用字体';

  @override
  String get downloadedOrphanFonts => '本地已下载（远程已下架）';

  @override
  String get orphanFontDescription =>
      '以下字体不再出现在远程仓库，但本地仍保留有字体文件。可在此处直接删除或继续应用。';

  @override
  String get fontListLoadFailed => '加载字体列表失败';

  @override
  String get systemFont => '跟随系统';

  @override
  String get systemFontSubtitle => '使用系统默认字体';

  @override
  String fontAuthorInfo(Object author, Object size) {
    return '作者：$author - 字体包体积：$size';
  }

  @override
  String get downloadFont => '下载字体';

  @override
  String get appliedFont => '已应用，点击取消使用';

  @override
  String get applyFont => '点击应用此字体';

  @override
  String get deleteDownloadedFont => '删除已下载字体';

  @override
  String get downloadFontFailedRetry => '下载失败，点击重试';

  @override
  String get deleteFont => '删除字体';

  @override
  String deleteSelectedFontConfirmation(Object fontName) {
    return '将删除「$fontName」的本地文件，并恢复为系统字体，确定继续？';
  }

  @override
  String deleteFontConfirmation(Object fontName) {
    return '确定删除「$fontName」的本地字体文件？';
  }

  @override
  String get previewLoadFailed => '预览加载失败';

  @override
  String get fontPreviewHeadline => '欢迎使用 AnimeFlow';

  @override
  String get orphanFontAvailable => '远程仓库已下架，仍可继续使用本地字体';

  @override
  String get orphanFontMissing => '本地字体文件已丢失，可在此处清理记录';

  @override
  String get confirmDelete => '确认删除';

  @override
  String deleteSourceConfirmation(Object name) {
    return '确定要删除数据源 \"$name\" 吗？此操作不可恢复。';
  }

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get deleteFailed => '删除失败';

  @override
  String sourceDeleted(Object name) {
    return '数据源 \"$name\" 已被删除';
  }

  @override
  String sourceDeleteFailed(Object error, Object name) {
    return '删除数据源 \"$name\" 时发生错误：$error';
  }

  @override
  String get downloadConfig => '下载配置';

  @override
  String get addSource => '添加数据源';

  @override
  String get editSource => '编辑数据源';

  @override
  String get saveFailed => '保存失败';

  @override
  String dataSaveFailed(Object error) {
    return '数据保存失败：$error';
  }

  @override
  String get fieldRequired => '此字段不能为空';

  @override
  String get versionNumber => '版本号';

  @override
  String get versionExample => '如（1.0.0）';

  @override
  String get sourceName => '名称';

  @override
  String get sourceNameHint => '网站名称，唯一值避免与其他配置名称重复，否则将被覆盖';

  @override
  String get iconLink => '图标链接';

  @override
  String get websiteLink => '网站链接';

  @override
  String get websiteLinkHint => '网站主链接，避免以 / 结尾';

  @override
  String get searchLink => '搜索链接';

  @override
  String searchLinkHint(Object keyword) {
    return '用$keyword搜索关键字，示例：https://dm.xifanacg.com/search.html?wd=$keyword';
  }

  @override
  String get searchContentList => '搜索内容列表';

  @override
  String get searchListName => '搜索列表名称';

  @override
  String get searchListLink => '搜索列表链接';

  @override
  String get lineName => '线路名称';

  @override
  String get episodeList => '剧集列表';

  @override
  String get episode => '剧集';

  @override
  String get episodeHint => '剧集链接，从剧集列表中获取的数据的 XPath';

  @override
  String get antiCrawlerOptional => '反爬 / 验证码（可选）';

  @override
  String get enableWebViewCaptcha => '启用 WebView 验证码处理';

  @override
  String get webViewCaptchaSubtitle => '搜索触发验证码时，用 WebView 完成验证并保存 Cookie';

  @override
  String get captchaType => '验证类型';

  @override
  String get imageCaptchaManual => '图片验证码（手动输入）';

  @override
  String get autoClickCaptcha => '自动点击验证按钮';

  @override
  String get captchaImageXPath => '验证码图片 XPath';

  @override
  String get captchaImageXPathHint => 'WebView 内定位验证码图片元素';

  @override
  String get captchaInputXPath => '验证码输入框 XPath';

  @override
  String get captchaInputXPathHint => '供用户输入验证码的 input 元素';

  @override
  String get submitCaptchaXPath => '提交验证码按钮 XPath';

  @override
  String get verifyButtonXPath => '验证按钮 XPath';

  @override
  String get submitCaptchaHint => '点击后提交验证码的按钮';

  @override
  String get autoClickCaptchaHint => '检测到后自动点击的验证按钮（如「我不是机器人」）';

  @override
  String get downloadSuccess => '下载成功';

  @override
  String pluginDownloaded(Object name) {
    return '插件 \"$name\" 已下载';
  }

  @override
  String pluginDownloadFailed(Object error, Object name) {
    return '下载插件 \"$name\" 时发生错误：$error';
  }

  @override
  String get updateSuccess => '更新成功';

  @override
  String pluginUpdated(Object name, Object version) {
    return '插件 \"$name\" 已更新到版本 $version';
  }

  @override
  String pluginUpdateFailed(Object error, Object name) {
    return '更新插件 \"$name\" 时发生错误：$error';
  }

  @override
  String get downloadSources => '下载数据源';

  @override
  String get downloadSourcesSubtitle => '当前会从 GitHub 仓库中下载数据源，注意网络环境，下拉刷新数据';

  @override
  String get useMirror => '使用镜像';

  @override
  String get useMirrorSubtitle => '无法直连 GitHub 时开启，通过镜像拉取插件列表';

  @override
  String get noDataRefresh => '没有找到数据，请刷新';

  @override
  String get downloaded => '已下载';

  @override
  String get updating => '更新中…';

  @override
  String get update => '更新';

  @override
  String pluginVersionDate(Object date, Object version) {
    return '版本：$version - $date';
  }

  @override
  String get collectionSyncTitle => '收藏同步';

  @override
  String get collectionSyncStarted => '收藏同步已开始';

  @override
  String get syncStartFailed => '启动同步失败';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get refreshStatusFailed => '刷新状态失败';

  @override
  String syncedItems(Object count) {
    return '已同步 $count 条';
  }

  @override
  String get syncInProgress => '同步进行中…';

  @override
  String get syncBangumiCollection => '同步 Bangumi 收藏';

  @override
  String get syncStatusLoadFailed => '获取同步状态失败';

  @override
  String get syncStatusIdle => '未同步';

  @override
  String get syncStatusRunning => '同步中';

  @override
  String get syncStatusSuccess => '同步完成';

  @override
  String get syncStatusFailed => '同步失败';

  @override
  String get introduction => '介绍';

  @override
  String get collection => '收藏';

  @override
  String get timeline => '时间线';

  @override
  String get userInfoUnavailable => '无法查询到用户信息';

  @override
  String get timelineComingSoon => '时间线功能待实现';

  @override
  String get statistics => '统计';

  @override
  String get bio => '个人简介';

  @override
  String get location => '所在地';

  @override
  String get website => '网站';

  @override
  String get mysteriousUser => '该用户很神秘';

  @override
  String get manualSearch => '手动搜索';

  @override
  String get manualSearchResource => '手动搜索资源';

  @override
  String fetchingResource(Object website) {
    return '正在获取 $website 的资源';
  }

  @override
  String get reSearchingResource => '当前站点正在重新检索，请稍候片刻。';

  @override
  String resourceRequestFailed(Object website) {
    return '$website 请求失败';
  }

  @override
  String resourceNotFoundForSite(Object website) {
    return '$website 暂未搜到资源';
  }

  @override
  String get noPlayableSourceHint => '没有检索到可用播放源。你可以稍后重试，或切换其他站点。';

  @override
  String get searchAgain => '重新搜索';

  @override
  String get unnamedLine => '未命名线路';

  @override
  String get descending => '倒序';

  @override
  String get ascending => '升序';

  @override
  String get lineFilter => '线路筛选';

  @override
  String get allLines => '全部线路';

  @override
  String currentEpisodeCount(Object count) {
    return '当前集($count)';
  }

  @override
  String allEpisodesCount(Object count) {
    return '全集($count)';
  }

  @override
  String get noPlayableSourceForEpisode => '当前剧集暂无可用播放源';

  @override
  String get episodeNotInResultsHint => '当前选中剧集不在这些结果里。你可以切到“全部集数”手动指定资源站集数。';

  @override
  String get episodeNoSourceHint => '当前剧集没有匹配到对应播放源。';

  @override
  String get noSelectableEpisodes => '暂无可选集数';

  @override
  String get siteNoEpisodes => '当前站点没有返回可用播放集数。';

  @override
  String videoSourceLoadFailed(Object error) {
    return '获取视频源失败: $error';
  }

  @override
  String get matchLabel => '匹配度:';

  @override
  String get verificationSuccess => '验证成功';

  @override
  String get verificationRetrying => '正在重新检索，请稍候…';

  @override
  String get enterCaptcha => '请输入验证码';

  @override
  String get captchaMayBeWrong => '验证码可能有误，请重新输入';

  @override
  String siteRequiresCaptcha(Object website) {
    return '$website 需要验证码验证';
  }

  @override
  String get verify => '进行验证';

  @override
  String siteAutoVerifying(Object website) {
    return '$website 正在自动完成验证，请稍候';
  }

  @override
  String captchaVerification(Object website) {
    return '$website 验证码验证';
  }

  @override
  String get loadingCaptchaImage => '正在加载验证码图片...';

  @override
  String get imageDecodeFailed => '图片解码失败';

  @override
  String episodeNumber(Object episode) {
    return '第$episode集';
  }

  @override
  String watchedLabel(Object progress) {
    return '观看$progress';
  }

  @override
  String playEpisode(Object episode) {
    return '播放（$episode）';
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
  String get fitAuto => '自動填充';

  @override
  String get fitCrop => '裁切填充';

  @override
  String get fitStretch => '拉伸填充';

  @override
  String get buffering => '正在緩衝...';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get updateAvailable => '有版本更新';

  @override
  String get disableAutoUpdate => '取消自動更新';

  @override
  String get updateLater => '稍後更新';

  @override
  String get cancelDownload => '取消下載';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateDownloadHint => '安裝包會在 GitHub 儲存庫中下載，部分地區網路速度較慢，請使用代理改善網路';

  @override
  String get downloading => '正在下載...';

  @override
  String get selectDownloadSource => '請選擇下載地址:';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get latestVersion => '目前已是最新版本';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String updateDownloadFailed(Object error) {
    return '更新下載失敗: $error';
  }

  @override
  String get downloadCancelled => '下載已取消';

  @override
  String get downloadCancelledMessage => '已取消下載';

  @override
  String get downloadComplete => '下載完成';

  @override
  String get packageDownloaded => '安裝包已下載完成';

  @override
  String get openFailed => '開啟失敗';

  @override
  String openFileManagerFailed(Object error) {
    return '無法開啟檔案管理器: $error';
  }

  @override
  String get openPackageFolder => '開啟安裝包資料夾';

  @override
  String get openSourceLicense => '開源授權條款';

  @override
  String get noLicenseInfo => '暫無授權資訊';

  @override
  String get noMoreContent => '沒有更多了';

  @override
  String get reload => '重新載入';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String get back => '返回';

  @override
  String get monday => '星期一';

  @override
  String get tuesday => '星期二';

  @override
  String get wednesday => '星期三';

  @override
  String get thursday => '星期四';

  @override
  String get friday => '星期五';

  @override
  String get saturday => '星期六';

  @override
  String get sunday => '星期日';

  @override
  String releaseCount(Object count) {
    return '$count 集';
  }

  @override
  String noUpdatesOnWeekday(Object weekday) {
    return '$weekday沒有番劇更新';
  }

  @override
  String get animeCount => '番劇數量';

  @override
  String get totalWatchers => '總觀看人數';

  @override
  String get averageRating => '平均評分';

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
  String get charactersLoadFailed => '載入角色資訊失敗';

  @override
  String get noCharacters => '暫無角色資訊';

  @override
  String get characterWorks => '出演作品';

  @override
  String get backToTop => '返回頂部';

  @override
  String get noComments => '暫無吐槽';

  @override
  String get characterWorksLoadFailed => '載入出演作品失敗';

  @override
  String get noCharacterWorks => '暫無出演作品';

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
  String get confirmAllWatched => '確認全部看過';

  @override
  String get confirmAllWatchedMessage => '確定要將此番劇的全部劇集標記為看過嗎？';

  @override
  String get markAllWatchedSuccess => '已將全部劇集標記為看過';

  @override
  String loadedEpisodes(Object count) {
    return '已載入 $count 集';
  }

  @override
  String get allWatched => '全部看過';

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
  String get imageSearch => '圖片搜尋';

  @override
  String get switchToUploadImage => '改為上傳圖片檔案';

  @override
  String get switchToImageUrl => '改為輸入圖片 URL';

  @override
  String get searching => '搜尋中...';

  @override
  String get startSearch => '開始搜尋';

  @override
  String get tapToSelectImage => '按一下選擇圖片';

  @override
  String get supportedImageFormats => '支援 JPG、PNG、WEBP 格式';

  @override
  String get imagePreviewFailed => '圖片預覽失敗';

  @override
  String get imageSelected => '已選擇圖片';

  @override
  String get tapToReselectImage => '按一下可重新選擇圖片';

  @override
  String get reselect => '重新選擇';

  @override
  String get enterImageUrl => '請輸入圖片連結';

  @override
  String get clear => '清除';

  @override
  String get enterImageUrlToPreview => '輸入圖片連結後預覽';

  @override
  String get imageLoadFailed => '圖片載入失敗';

  @override
  String get checkImageUrl => '請檢查連結是否有效';

  @override
  String get recognizingImage => '正在辨識圖片';

  @override
  String get matchingAnimeFromImage => '請稍候，正在從截圖中匹配番劇資訊';

  @override
  String get imageSearchResultPlaceholder => '搜尋結果將在這裡顯示';

  @override
  String get noImageSearchResults => '未取得搜尋結果';

  @override
  String get startImageSearchHint => '選擇圖片檔案或輸入圖片連結後開始搜尋';

  @override
  String get recognitionResults => '辨識結果';

  @override
  String get originalAspectRatioTip => '僅支援使用原始比例番劇截圖搜尋結果';

  @override
  String get clearScreenshotTip => '截圖應清晰，避免過度壓縮或新增浮水印';

  @override
  String get searchEnginePoweredBy => '搜尋引擎由 ';

  @override
  String get providesSupport => ' 提供支援';

  @override
  String get searchAnimeByImage => '以圖搜番';

  @override
  String get searchSuggestions => '搜尋建議';

  @override
  String searchResultCount(Object count) {
    return '搜尋到 $count 筆內容';
  }

  @override
  String get enterKeywordToSearch => '輸入關鍵字開始搜尋';

  @override
  String get searchHistory => '搜尋記錄';

  @override
  String get clearAll => '全部清除';

  @override
  String get delete => '刪除';

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

  @override
  String get danmakuDisplayType => '彈幕顯示類型';

  @override
  String get scrollingDanmaku => '滾動彈幕';

  @override
  String get topDanmaku => '頂部彈幕';

  @override
  String get bottomDanmaku => '底部彈幕';

  @override
  String get danmakuSourcePlatform => '彈幕來源平台';

  @override
  String get danmakuStyle => '彈幕樣式';

  @override
  String get showBorder => '顯示邊框';

  @override
  String get showColor => '顯示顏色';

  @override
  String get massiveMode => '密集模式';

  @override
  String get danmakuSpeedTitle => '彈幕速度';

  @override
  String danmakuSpeed(Object percent) {
    return '速度：$percent%';
  }

  @override
  String get opacity => '透明度';

  @override
  String get fontSize => '字型大小';

  @override
  String get displayArea => '顯示區域';

  @override
  String get logoutSuccess => '已登出';

  @override
  String get openAuthorizationFailed => '開啟授權頁面失敗';

  @override
  String get loginStateLoadFailed => '載入登入狀態失敗';

  @override
  String get notLoggedIn => '尚未登入';

  @override
  String get loginToManageAccount => '登入後可管理帳戶資訊、綁定 Bangumi 帳戶';

  @override
  String get login => '登入';

  @override
  String get error => '錯誤';

  @override
  String get moreActions => '更多操作';

  @override
  String get unableOpenLink => '無法開啟連結';

  @override
  String get websiteLinkCopied => '網站連結已複製到剪貼簿';

  @override
  String saveImageFailed(Object error) {
    return '儲存圖片失敗: $error';
  }

  @override
  String get openInBrowser => '在瀏覽器中查看';

  @override
  String get downloadCover => '下載封面';

  @override
  String get copyWebsite => '複製網站連結';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get welcomeTo => '歡迎來到 ';

  @override
  String get loginToManageCollection => '登入後管理收藏';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get enterEmail => '請輸入電子郵件';

  @override
  String get invalidEmail => '請輸入有效的電子郵件';

  @override
  String get enterPassword => '請輸入密碼';

  @override
  String get passwordMinLength => '密碼至少需要 6 位';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get forgotPassword => '忘記密碼';

  @override
  String get loggingIn => '登入中...';

  @override
  String get bangumiAuthorizeLogin => 'Bangumi 授權登入';

  @override
  String get bangumi => 'Bangumi';

  @override
  String get noAccount => '還沒有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get authorizeLogin => '授權登入';

  @override
  String get registerAccount => '註冊帳戶';

  @override
  String get registerSuccess => '註冊成功';

  @override
  String get registerTitle => '註冊';

  @override
  String get createAccount => '建立帳號';

  @override
  String get registerSubtitle => '加入 AnimeFlow，同步你的追番體驗';

  @override
  String get enterGraphicCaptcha => '請先填寫圖形驗證碼';

  @override
  String get emailCodeSent => '驗證碼已寄出，請查收電子郵件';

  @override
  String get invalidEmailFormat => '電子郵件格式不正確';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get passwordLengthRange => '密碼長度需在 6-30 位之間';

  @override
  String get enterConfirmPassword => '請再次輸入密碼';

  @override
  String get passwordMismatch => '兩次輸入的密碼不一致';

  @override
  String get emailVerificationCode => '電子郵件驗證碼';

  @override
  String get enterEmailCode => '請輸入電子郵件驗證碼';

  @override
  String get emailCodeLength => '驗證碼必須為 6 位數字';

  @override
  String get haveAccountBackToLogin => '已有帳號？返回登入';

  @override
  String get accountInfo => '帳戶資訊';

  @override
  String get thirdPartyAccounts => '第三方帳戶';

  @override
  String get accountActions => '帳戶操作';

  @override
  String get nicknameUpdated => '暱稱已更新';

  @override
  String get waitingBangumiAuthorization => '正在等待 Bangumi 授權結果...';

  @override
  String get authorizing => '授權中...';

  @override
  String get bound => '已綁定';

  @override
  String get unbound => '未綁定';

  @override
  String get loading => '載入中...';

  @override
  String get bindStatusLoadFailed => '取得綁定狀態失敗';

  @override
  String get bindBangumiHint => '綁定 Bangumi 帳戶後可同步收藏等資料';

  @override
  String get bindBangumiAccount => '綁定 Bangumi 帳戶';

  @override
  String get confirmUnbind => '確認解除綁定';

  @override
  String get unbindConfirmation => '確定要解除綁定 Bangumi 帳戶嗎？解除後可能影響部分功能。';

  @override
  String get confirmUnbindAction => '確定解除綁定';

  @override
  String get unbind => '解除綁定';

  @override
  String get bangumiBindSuccessHint => 'Bangumi 授權與綁定應可正常使用。';

  @override
  String get bangumiBindFailureHint => '授權或綁定 Bangumi 時，建議開啟 VPN 或 Proxy 後再試。';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get autoUpdate => '自動更新';

  @override
  String get checkUpdate => '檢查更新';

  @override
  String get openSource => '開源地址';

  @override
  String get unableOpenWeb => '無法開啟網頁';

  @override
  String get deviceUnsupportedWeb => '你的裝置可能不支援此功能';

  @override
  String get thanks => '鳴謝';

  @override
  String get privacyPolicy => '私隱政策';

  @override
  String get specialThanks => '特別鳴謝';

  @override
  String get thanksDescription => '感謝以下優秀的開源專案和技術支援，讓 AnimeFlow 變得更好';

  @override
  String get kazumiWebViewSupport => 'Kazumi 專案提供的 WebView 技術支援';

  @override
  String get mediaKitDescription => '跨平台影片播放器，支援高品質影片播放';

  @override
  String get canvasDanmakuDescription => '彈幕插件，提供流暢的彈幕繪製';

  @override
  String get dandanplayDescription => '提供豐富的彈幕資料來源';

  @override
  String get bangumiDescription => '提供番劇資訊和使用者資料同步服務';

  @override
  String get anime4kDescription => '超解析度技術，提升影片畫質';

  @override
  String get traceMoeDescription => '提供以圖識別番劇功能';

  @override
  String fontRefreshFailed(Object error) {
    return '重新整理失敗：$error';
  }

  @override
  String get fontStylePageTitle => '字型樣式';

  @override
  String get refreshFontList => '重新整理字型列表';

  @override
  String get fontLibrary => '字型庫';

  @override
  String get cdnAcceleration => 'CDN 加速';

  @override
  String get fontDelayHint => '新上架的字型可能會延遲顯示';

  @override
  String get cdnTooltip => '開啟：經 jsDelivr 取得字型；關閉：直連 GitHub Raw（透過鏡像）';

  @override
  String get fontRestartHint => '如果字型效果沒有完整顯示，請重新啟動應用程式';

  @override
  String get noOtherFonts => '暫無其他可用字型';

  @override
  String get downloadedOrphanFonts => '本機已下載（遠端已下架）';

  @override
  String get orphanFontDescription =>
      '以下字型不再出現在遠端儲存庫，但本機仍保留字型檔案。可在此處直接刪除或繼續套用。';

  @override
  String get fontListLoadFailed => '載入字型列表失敗';

  @override
  String get systemFont => '跟隨系統';

  @override
  String get systemFontSubtitle => '使用系統預設字型';

  @override
  String fontAuthorInfo(Object author, Object size) {
    return '作者：$author - 字型包大小：$size';
  }

  @override
  String get downloadFont => '下載字型';

  @override
  String get appliedFont => '已套用，點擊取消使用';

  @override
  String get applyFont => '點擊套用此字型';

  @override
  String get deleteDownloadedFont => '刪除已下載字型';

  @override
  String get downloadFontFailedRetry => '下載失敗，點擊重試';

  @override
  String get deleteFont => '刪除字型';

  @override
  String deleteSelectedFontConfirmation(Object fontName) {
    return '將刪除「$fontName」的本機檔案，並恢復為系統字型，確定繼續？';
  }

  @override
  String deleteFontConfirmation(Object fontName) {
    return '確定刪除「$fontName」的本機字型檔案？';
  }

  @override
  String get previewLoadFailed => '預覽載入失敗';

  @override
  String get fontPreviewHeadline => '歡迎使用 AnimeFlow';

  @override
  String get orphanFontAvailable => '遠端儲存庫已下架，仍可繼續使用本機字型';

  @override
  String get orphanFontMissing => '本機字型檔案已遺失，可在此處清理記錄';

  @override
  String get collectionSyncTitle => '收藏同步';

  @override
  String get collectionSyncStarted => '收藏同步已開始';

  @override
  String get syncStartFailed => '啟動同步失敗';

  @override
  String get refreshStatus => '重新整理狀態';

  @override
  String get refreshStatusFailed => '重新整理狀態失敗';

  @override
  String syncedItems(Object count) {
    return '已同步 $count 條';
  }

  @override
  String get syncInProgress => '同步進行中…';

  @override
  String get syncBangumiCollection => '同步 Bangumi 收藏';

  @override
  String get syncStatusLoadFailed => '取得同步狀態失敗';

  @override
  String get syncStatusIdle => '未同步';

  @override
  String get syncStatusRunning => '同步中';

  @override
  String get syncStatusSuccess => '同步完成';

  @override
  String get syncStatusFailed => '同步失敗';

  @override
  String get introduction => '介紹';

  @override
  String get collection => '收藏';

  @override
  String get timeline => '時間軸';

  @override
  String get userInfoUnavailable => '無法取得使用者資訊';

  @override
  String get timelineComingSoon => '時間軸功能即將推出';

  @override
  String get statistics => '統計';

  @override
  String get bio => '個人簡介';

  @override
  String get location => '所在地';

  @override
  String get website => '網站';

  @override
  String get mysteriousUser => '這位使用者很神秘';

  @override
  String get manualSearch => '手動搜尋';

  @override
  String get manualSearchResource => '手動搜尋資源';

  @override
  String fetchingResource(Object website) {
    return '正在取得 $website 的資源';
  }

  @override
  String get reSearchingResource => '目前網站正在重新搜尋，請稍候片刻。';

  @override
  String resourceRequestFailed(Object website) {
    return '$website 請求失敗';
  }

  @override
  String resourceNotFoundForSite(Object website) {
    return '$website 暫未搜尋到資源';
  }

  @override
  String get noPlayableSourceHint => '沒有搜尋到可用播放來源。你可以稍後重試，或切換其他網站。';

  @override
  String get searchAgain => '重新搜尋';

  @override
  String get unnamedLine => '未命名線路';

  @override
  String get descending => '降冪';

  @override
  String get ascending => '升冪';

  @override
  String get lineFilter => '線路篩選';

  @override
  String get allLines => '全部線路';

  @override
  String currentEpisodeCount(Object count) {
    return '目前集數($count)';
  }

  @override
  String allEpisodesCount(Object count) {
    return '全集($count)';
  }

  @override
  String get noPlayableSourceForEpisode => '目前劇集沒有可用播放來源';

  @override
  String get episodeNotInResultsHint =>
      '目前選取的劇集不在這些結果中。你可以切換到「全部集數」手動指定資源網站集數。';

  @override
  String get episodeNoSourceHint => '目前劇集沒有找到相符的播放來源。';

  @override
  String get noSelectableEpisodes => '沒有可選集數';

  @override
  String get siteNoEpisodes => '目前網站沒有回傳可用播放集數。';

  @override
  String videoSourceLoadFailed(Object error) {
    return '取得影片來源失敗：$error';
  }

  @override
  String get matchLabel => '相符度：';

  @override
  String get verificationSuccess => '驗證成功';

  @override
  String get verificationRetrying => '正在重新搜尋，請稍候…';

  @override
  String get enterCaptcha => '請輸入驗證碼';

  @override
  String get captchaMayBeWrong => '驗證碼可能有誤，請重新輸入';

  @override
  String siteRequiresCaptcha(Object website) {
    return '$website 需要驗證碼驗證';
  }

  @override
  String get verify => '進行驗證';

  @override
  String siteAutoVerifying(Object website) {
    return '$website 正在自動完成驗證，請稍候';
  }

  @override
  String captchaVerification(Object website) {
    return '$website 驗證碼驗證';
  }

  @override
  String get loadingCaptchaImage => '正在載入驗證碼圖片…';

  @override
  String get imageDecodeFailed => '圖片解碼失敗';

  @override
  String episodeNumber(Object episode) {
    return '第$episode集';
  }

  @override
  String watchedLabel(Object progress) {
    return '觀看$progress';
  }

  @override
  String playEpisode(Object episode) {
    return '播放（$episode）';
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
  String get fitAuto => '自動填充';

  @override
  String get fitCrop => '裁切填充';

  @override
  String get fitStretch => '拉伸填充';

  @override
  String get buffering => '正在緩衝...';

  @override
  String get loadFailed => '載入失敗';

  @override
  String get updateAvailable => '有版本更新';

  @override
  String get disableAutoUpdate => '取消自動更新';

  @override
  String get updateLater => '稍後更新';

  @override
  String get cancelDownload => '取消下載';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateDownloadHint => '安裝包會在 GitHub 儲存庫中下載，部分地區網路速度較慢，請使用代理改善網路';

  @override
  String get downloading => '正在下載...';

  @override
  String get selectDownloadSource => '請選擇下載地址:';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get latestVersion => '目前已是最新版本';

  @override
  String get downloadFailed => '下載失敗';

  @override
  String updateDownloadFailed(Object error) {
    return '更新下載失敗: $error';
  }

  @override
  String get downloadCancelled => '下載已取消';

  @override
  String get downloadCancelledMessage => '已取消下載';

  @override
  String get downloadComplete => '下載完成';

  @override
  String get packageDownloaded => '安裝包已下載完成';

  @override
  String get openFailed => '開啟失敗';

  @override
  String openFileManagerFailed(Object error) {
    return '無法開啟檔案管理器: $error';
  }

  @override
  String get openPackageFolder => '開啟安裝包資料夾';

  @override
  String get openSourceLicense => '開源授權條款';

  @override
  String get noLicenseInfo => '暫無授權資訊';

  @override
  String get noMoreContent => '沒有更多了';

  @override
  String get reload => '重新載入';

  @override
  String get todayBroadcast => '今日放送';

  @override
  String get back => '返回';

  @override
  String get monday => '週一';

  @override
  String get tuesday => '週二';

  @override
  String get wednesday => '週三';

  @override
  String get thursday => '週四';

  @override
  String get friday => '週五';

  @override
  String get saturday => '週六';

  @override
  String get sunday => '週日';

  @override
  String releaseCount(Object count) {
    return '$count 部';
  }

  @override
  String noUpdatesOnWeekday(Object weekday) {
    return '$weekday無番劇更新';
  }

  @override
  String get animeCount => '番劇數量';

  @override
  String get totalWatchers => '總觀看人數';

  @override
  String get averageRating => '平均評分';

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
  String get charactersLoadFailed => '載入角色資訊失敗';

  @override
  String get noCharacters => '暫無角色資訊';

  @override
  String get characterWorks => '出演作品';

  @override
  String get backToTop => '返回頂部';

  @override
  String get noComments => '暫無吐槽';

  @override
  String get characterWorksLoadFailed => '載入出演作品失敗';

  @override
  String get noCharacterWorks => '暫無出演作品';

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
  String get confirmAllWatched => '確認全部看過';

  @override
  String get confirmAllWatchedMessage => '確定要將此番劇的全部劇集標記為看過嗎？';

  @override
  String get markAllWatchedSuccess => '已將全部劇集標記為看過';

  @override
  String loadedEpisodes(Object count) {
    return '已載入 $count 集';
  }

  @override
  String get allWatched => '全部看過';

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
  String get imageSearch => '圖片搜尋';

  @override
  String get switchToUploadImage => '改為上傳圖片檔案';

  @override
  String get switchToImageUrl => '改為輸入圖片 URL';

  @override
  String get searching => '搜尋中...';

  @override
  String get startSearch => '開始搜尋';

  @override
  String get tapToSelectImage => '點選選擇圖片';

  @override
  String get supportedImageFormats => '支援 JPG、PNG、WEBP 格式';

  @override
  String get imagePreviewFailed => '圖片預覽失敗';

  @override
  String get imageSelected => '已選擇圖片';

  @override
  String get tapToReselectImage => '點選可重新選擇圖片';

  @override
  String get reselect => '重新選擇';

  @override
  String get enterImageUrl => '請輸入圖片連結';

  @override
  String get clear => '清除';

  @override
  String get enterImageUrlToPreview => '輸入圖片連結後預覽';

  @override
  String get imageLoadFailed => '圖片載入失敗';

  @override
  String get checkImageUrl => '請檢查連結是否有效';

  @override
  String get recognizingImage => '正在辨識圖片';

  @override
  String get matchingAnimeFromImage => '請稍候，正在從截圖中匹配番劇資訊';

  @override
  String get imageSearchResultPlaceholder => '搜尋結果將在這裡顯示';

  @override
  String get noImageSearchResults => '未取得搜尋結果';

  @override
  String get startImageSearchHint => '選擇圖片檔案或輸入圖片連結後開始搜尋';

  @override
  String get recognitionResults => '辨識結果';

  @override
  String get originalAspectRatioTip => '僅支援使用原始比例番劇截圖搜尋結果';

  @override
  String get clearScreenshotTip => '截圖應清晰，避免過度壓縮或新增浮水印';

  @override
  String get searchEnginePoweredBy => '搜尋引擎由 ';

  @override
  String get providesSupport => ' 提供支援';

  @override
  String get searchAnimeByImage => '以圖搜番';

  @override
  String get searchSuggestions => '搜尋建議';

  @override
  String searchResultCount(Object count) {
    return '搜尋到 $count 筆內容';
  }

  @override
  String get enterKeywordToSearch => '輸入關鍵字開始搜尋';

  @override
  String get searchHistory => '搜尋記錄';

  @override
  String get clearAll => '全部清除';

  @override
  String get delete => '刪除';

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

  @override
  String get danmakuDisplayType => '彈幕顯示類型';

  @override
  String get scrollingDanmaku => '滾動彈幕';

  @override
  String get topDanmaku => '頂部彈幕';

  @override
  String get bottomDanmaku => '底部彈幕';

  @override
  String get danmakuSourcePlatform => '彈幕來源平台';

  @override
  String get danmakuStyle => '彈幕樣式';

  @override
  String get showBorder => '顯示邊框';

  @override
  String get showColor => '顯示顏色';

  @override
  String get massiveMode => '密集模式';

  @override
  String get danmakuSpeedTitle => '彈幕速度';

  @override
  String danmakuSpeed(Object percent) {
    return '速度：$percent%';
  }

  @override
  String get opacity => '透明度';

  @override
  String get fontSize => '字型大小';

  @override
  String get displayArea => '顯示區域';

  @override
  String get logoutSuccess => '已登出';

  @override
  String get openAuthorizationFailed => '開啟授權頁面失敗';

  @override
  String get loginStateLoadFailed => '載入登入狀態失敗';

  @override
  String get notLoggedIn => '尚未登入';

  @override
  String get loginToManageAccount => '登入後可管理帳戶資訊、綁定 Bangumi 帳戶';

  @override
  String get login => '登入';

  @override
  String get error => '錯誤';

  @override
  String get moreActions => '更多操作';

  @override
  String get unableOpenLink => '無法開啟連結';

  @override
  String get websiteLinkCopied => '網站連結已複製到剪貼簿';

  @override
  String saveImageFailed(Object error) {
    return '儲存圖片失敗: $error';
  }

  @override
  String get openInBrowser => '在瀏覽器中查看';

  @override
  String get downloadCover => '下載封面';

  @override
  String get copyWebsite => '複製網站連結';

  @override
  String get loginSuccess => '登入成功';

  @override
  String get welcomeTo => '歡迎來到 ';

  @override
  String get loginToManageCollection => '登入後管理收藏';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get enterEmail => '請輸入電子郵件';

  @override
  String get invalidEmail => '請輸入有效的電子郵件';

  @override
  String get enterPassword => '請輸入密碼';

  @override
  String get passwordMinLength => '密碼至少需要 6 位';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String get forgotPassword => '忘記密碼';

  @override
  String get loggingIn => '登入中...';

  @override
  String get bangumiAuthorizeLogin => 'Bangumi 授權登入';

  @override
  String get bangumi => 'Bangumi';

  @override
  String get noAccount => '還沒有帳號？';

  @override
  String get registerNow => '立即註冊';

  @override
  String get authorizeLogin => '授權登入';

  @override
  String get registerAccount => '註冊帳戶';

  @override
  String get registerSuccess => '註冊成功';

  @override
  String get registerTitle => '註冊';

  @override
  String get createAccount => '建立帳號';

  @override
  String get registerSubtitle => '加入 AnimeFlow，同步你的追番體驗';

  @override
  String get enterGraphicCaptcha => '請先填寫圖形驗證碼';

  @override
  String get emailCodeSent => '驗證碼已寄出，請查收電子郵件';

  @override
  String get invalidEmailFormat => '電子郵件格式不正確';

  @override
  String get confirmPassword => '確認密碼';

  @override
  String get passwordLengthRange => '密碼長度需在 6-30 位之間';

  @override
  String get enterConfirmPassword => '請再次輸入密碼';

  @override
  String get passwordMismatch => '兩次輸入的密碼不一致';

  @override
  String get emailVerificationCode => '電子郵件驗證碼';

  @override
  String get enterEmailCode => '請輸入電子郵件驗證碼';

  @override
  String get emailCodeLength => '驗證碼必須為 6 位數字';

  @override
  String get haveAccountBackToLogin => '已有帳號？返回登入';

  @override
  String get accountInfo => '帳戶資訊';

  @override
  String get thirdPartyAccounts => '第三方帳戶';

  @override
  String get accountActions => '帳戶操作';

  @override
  String get nicknameUpdated => '暱稱已更新';

  @override
  String get waitingBangumiAuthorization => '正在等待 Bangumi 授權結果...';

  @override
  String get authorizing => '授權中...';

  @override
  String get bound => '已綁定';

  @override
  String get unbound => '未綁定';

  @override
  String get loading => '載入中...';

  @override
  String get bindStatusLoadFailed => '取得綁定狀態失敗';

  @override
  String get bindBangumiHint => '綁定 Bangumi 帳戶後可同步收藏等資料';

  @override
  String get bindBangumiAccount => '綁定 Bangumi 帳戶';

  @override
  String get confirmUnbind => '確認解除綁定';

  @override
  String get unbindConfirmation => '確定要解除綁定 Bangumi 帳戶嗎？解除後可能影響部分功能。';

  @override
  String get confirmUnbindAction => '確定解除綁定';

  @override
  String get unbind => '解除綁定';

  @override
  String get bangumiBindSuccessHint => 'Bangumi 授權與綁定應可正常使用。';

  @override
  String get bangumiBindFailureHint => '授權或綁定 Bangumi 時，建議開啟 VPN 或 Proxy 後再試。';

  @override
  String version(Object version) {
    return '版本 $version';
  }

  @override
  String get autoUpdate => '自動更新';

  @override
  String get checkUpdate => '檢查更新';

  @override
  String get openSource => '開源地址';

  @override
  String get unableOpenWeb => '無法開啟網頁';

  @override
  String get deviceUnsupportedWeb => '你的裝置可能不支援此功能';

  @override
  String get thanks => '鳴謝';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get specialThanks => '特別鳴謝';

  @override
  String get thanksDescription => '感謝以下優秀的開源專案和技術支援，讓 AnimeFlow 變得更好';

  @override
  String get kazumiWebViewSupport => 'Kazumi 專案提供的 WebView 技術支援';

  @override
  String get mediaKitDescription => '跨平台影片播放器，支援高品質影片播放';

  @override
  String get canvasDanmakuDescription => '彈幕插件，提供流暢的彈幕繪製';

  @override
  String get dandanplayDescription => '提供豐富的彈幕資料來源';

  @override
  String get bangumiDescription => '提供番劇資訊和使用者資料同步服務';

  @override
  String get anime4kDescription => '超解析度技術，提升影片畫質';

  @override
  String get traceMoeDescription => '提供以圖識別番劇功能';

  @override
  String fontRefreshFailed(Object error) {
    return '重新整理失敗：$error';
  }

  @override
  String get fontStylePageTitle => '字型樣式';

  @override
  String get refreshFontList => '重新整理字型列表';

  @override
  String get fontLibrary => '字型庫';

  @override
  String get cdnAcceleration => 'CDN 加速';

  @override
  String get fontDelayHint => '新上架的字型可能會延遲顯示';

  @override
  String get cdnTooltip => '開啟：經 jsDelivr 取得字型；關閉：直連 GitHub Raw（透過鏡像）';

  @override
  String get fontRestartHint => '如果字型效果沒有完整顯示，請重新啟動應用程式';

  @override
  String get noOtherFonts => '暫無其他可用字型';

  @override
  String get downloadedOrphanFonts => '本機已下載（遠端已下架）';

  @override
  String get orphanFontDescription =>
      '以下字型不再出現在遠端儲存庫，但本機仍保留字型檔案。可在此處直接刪除或繼續套用。';

  @override
  String get fontListLoadFailed => '載入字型列表失敗';

  @override
  String get systemFont => '跟隨系統';

  @override
  String get systemFontSubtitle => '使用系統預設字型';

  @override
  String fontAuthorInfo(Object author, Object size) {
    return '作者：$author - 字型包大小：$size';
  }

  @override
  String get downloadFont => '下載字型';

  @override
  String get appliedFont => '已套用，點擊取消使用';

  @override
  String get applyFont => '點擊套用此字型';

  @override
  String get deleteDownloadedFont => '刪除已下載字型';

  @override
  String get downloadFontFailedRetry => '下載失敗，點擊重試';

  @override
  String get deleteFont => '刪除字型';

  @override
  String deleteSelectedFontConfirmation(Object fontName) {
    return '將刪除「$fontName」的本機檔案，並恢復為系統字型，確定繼續？';
  }

  @override
  String deleteFontConfirmation(Object fontName) {
    return '確定刪除「$fontName」的本機字型檔案？';
  }

  @override
  String get previewLoadFailed => '預覽載入失敗';

  @override
  String get fontPreviewHeadline => '歡迎使用 AnimeFlow';

  @override
  String get orphanFontAvailable => '遠端儲存庫已下架，仍可繼續使用本機字型';

  @override
  String get orphanFontMissing => '本機字型檔案已遺失，可在此處清理記錄';

  @override
  String get collectionSyncTitle => '收藏同步';

  @override
  String get collectionSyncStarted => '收藏同步已開始';

  @override
  String get syncStartFailed => '啟動同步失敗';

  @override
  String get refreshStatus => '重新整理狀態';

  @override
  String get refreshStatusFailed => '重新整理狀態失敗';

  @override
  String syncedItems(Object count) {
    return '已同步 $count 筆';
  }

  @override
  String get syncInProgress => '同步進行中…';

  @override
  String get syncBangumiCollection => '同步 Bangumi 收藏';

  @override
  String get syncStatusLoadFailed => '取得同步狀態失敗';

  @override
  String get syncStatusIdle => '未同步';

  @override
  String get syncStatusRunning => '同步中';

  @override
  String get syncStatusSuccess => '同步完成';

  @override
  String get syncStatusFailed => '同步失敗';

  @override
  String get introduction => '介紹';

  @override
  String get collection => '收藏';

  @override
  String get timeline => '時間軸';

  @override
  String get userInfoUnavailable => '無法取得使用者資訊';

  @override
  String get timelineComingSoon => '時間軸功能即將推出';

  @override
  String get statistics => '統計';

  @override
  String get bio => '個人簡介';

  @override
  String get location => '所在地';

  @override
  String get website => '網站';

  @override
  String get mysteriousUser => '這位使用者很神秘';

  @override
  String get manualSearch => '手動搜尋';

  @override
  String get manualSearchResource => '手動搜尋資源';

  @override
  String fetchingResource(Object website) {
    return '正在取得 $website 的資源';
  }

  @override
  String get reSearchingResource => '目前網站正在重新搜尋，請稍候片刻。';

  @override
  String resourceRequestFailed(Object website) {
    return '$website 請求失敗';
  }

  @override
  String resourceNotFoundForSite(Object website) {
    return '$website 暫未搜尋到資源';
  }

  @override
  String get noPlayableSourceHint => '沒有搜尋到可用播放來源。你可以稍後重試，或切換其他網站。';

  @override
  String get searchAgain => '重新搜尋';

  @override
  String get unnamedLine => '未命名線路';

  @override
  String get descending => '降冪';

  @override
  String get ascending => '升冪';

  @override
  String get lineFilter => '線路篩選';

  @override
  String get allLines => '全部線路';

  @override
  String currentEpisodeCount(Object count) {
    return '目前集數($count)';
  }

  @override
  String allEpisodesCount(Object count) {
    return '全集($count)';
  }

  @override
  String get noPlayableSourceForEpisode => '目前劇集沒有可用播放來源';

  @override
  String get episodeNotInResultsHint =>
      '目前選取的劇集不在這些結果中。你可以切換到「全部集數」手動指定資源網站集數。';

  @override
  String get episodeNoSourceHint => '目前劇集沒有找到相符的播放來源。';

  @override
  String get noSelectableEpisodes => '沒有可選集數';

  @override
  String get siteNoEpisodes => '目前網站沒有回傳可用播放集數。';

  @override
  String videoSourceLoadFailed(Object error) {
    return '取得影片來源失敗：$error';
  }

  @override
  String get matchLabel => '相符度：';

  @override
  String get verificationSuccess => '驗證成功';

  @override
  String get verificationRetrying => '正在重新搜尋，請稍候…';

  @override
  String get enterCaptcha => '請輸入驗證碼';

  @override
  String get captchaMayBeWrong => '驗證碼可能有誤，請重新輸入';

  @override
  String siteRequiresCaptcha(Object website) {
    return '$website 需要驗證碼驗證';
  }

  @override
  String get verify => '進行驗證';

  @override
  String siteAutoVerifying(Object website) {
    return '$website 正在自動完成驗證，請稍候';
  }

  @override
  String captchaVerification(Object website) {
    return '$website 驗證碼驗證';
  }

  @override
  String get loadingCaptchaImage => '正在載入驗證碼圖片…';

  @override
  String get imageDecodeFailed => '圖片解碼失敗';

  @override
  String episodeNumber(Object episode) {
    return '第$episode集';
  }

  @override
  String watchedLabel(Object progress) {
    return '觀看$progress';
  }

  @override
  String playEpisode(Object episode) {
    return '播放（$episode）';
  }
}
