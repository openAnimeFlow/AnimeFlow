import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
        languageCode: 'zh', countryCode: 'HK', scriptCode: 'Hant'),
    Locale.fromSubtags(
        languageCode: 'zh', countryCode: 'TW', scriptCode: 'Hant')
  ];

  /// No description provided for @generalSettingsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'通用设置'**
  String get generalSettingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'语言'**
  String get languageLabel;

  /// No description provided for @selectLanguageTooltip.
  ///
  /// In zh_Hans, this message translates to:
  /// **'选择语言'**
  String get selectLanguageTooltip;

  /// No description provided for @simplifiedChinese.
  ///
  /// In zh_Hans, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @traditionalChineseTaiwan.
  ///
  /// In zh_Hans, this message translates to:
  /// **'繁體中文（台灣）'**
  String get traditionalChineseTaiwan;

  /// No description provided for @traditionalChineseHongKong.
  ///
  /// In zh_Hans, this message translates to:
  /// **'繁體中文（香港）'**
  String get traditionalChineseHongKong;

  /// No description provided for @englishLanguage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @recommendTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'推荐'**
  String get recommendTab;

  /// No description provided for @rankingTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'排行'**
  String get rankingTab;

  /// No description provided for @mineTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'我的'**
  String get mineTab;

  /// No description provided for @settingsLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'设置'**
  String get settingsLabel;

  /// No description provided for @animeTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'动漫'**
  String get animeTab;

  /// No description provided for @forumTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'论坛'**
  String get forumTab;

  /// No description provided for @searchAnimeHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索动漫番剧...'**
  String get searchAnimeHint;

  /// No description provided for @playHistorySection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放记录'**
  String get playHistorySection;

  /// No description provided for @viewMore.
  ///
  /// In zh_Hans, this message translates to:
  /// **'查看更多'**
  String get viewMore;

  /// No description provided for @watchedProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'看到{episode}话 {progress}'**
  String watchedProgress(Object episode, Object progress);

  /// No description provided for @popularAnimeTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'热门动画'**
  String get popularAnimeTitle;

  /// No description provided for @fitAuto.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动填充'**
  String get fitAuto;

  /// No description provided for @fitCrop.
  ///
  /// In zh_Hans, this message translates to:
  /// **'裁剪填充'**
  String get fitCrop;

  /// No description provided for @fitStretch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'拉伸填充'**
  String get fitStretch;

  /// No description provided for @buffering.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在缓冲...'**
  String get buffering;

  /// No description provided for @loadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @updateAvailable.
  ///
  /// In zh_Hans, this message translates to:
  /// **'有版本更新'**
  String get updateAvailable;

  /// No description provided for @disableAutoUpdate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'取消自动更新'**
  String get disableAutoUpdate;

  /// No description provided for @updateLater.
  ///
  /// In zh_Hans, this message translates to:
  /// **'稍后更新'**
  String get updateLater;

  /// No description provided for @cancelDownload.
  ///
  /// In zh_Hans, this message translates to:
  /// **'取消下载'**
  String get cancelDownload;

  /// No description provided for @updateNow.
  ///
  /// In zh_Hans, this message translates to:
  /// **'立即更新'**
  String get updateNow;

  /// No description provided for @updateDownloadHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'安装包会在 GitHub 仓库中下载，国内网络速度较慢，请使用代理改善网络'**
  String get updateDownloadHint;

  /// No description provided for @downloading.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在下载...'**
  String get downloading;

  /// No description provided for @selectDownloadSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请选择下载地址:'**
  String get selectDownloadSource;

  /// No description provided for @checkForUpdates.
  ///
  /// In zh_Hans, this message translates to:
  /// **'检查更新'**
  String get checkForUpdates;

  /// No description provided for @latestVersion.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前为最新版本'**
  String get latestVersion;

  /// No description provided for @downloadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载失败'**
  String get downloadFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新下载失败: {error}'**
  String updateDownloadFailed(Object error);

  /// No description provided for @downloadCancelled.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载已取消'**
  String get downloadCancelled;

  /// No description provided for @downloadCancelledMessage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已取消下载'**
  String get downloadCancelledMessage;

  /// No description provided for @downloadComplete.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载完成'**
  String get downloadComplete;

  /// No description provided for @packageDownloaded.
  ///
  /// In zh_Hans, this message translates to:
  /// **'安装包已下载完成'**
  String get packageDownloaded;

  /// No description provided for @openFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'打开失败'**
  String get openFailed;

  /// No description provided for @openFileManagerFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法打开文件管理器: {error}'**
  String openFileManagerFailed(Object error);

  /// No description provided for @openPackageFolder.
  ///
  /// In zh_Hans, this message translates to:
  /// **'打开安装包文件夹'**
  String get openPackageFolder;

  /// No description provided for @openSourceLicense.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开源协议'**
  String get openSourceLicense;

  /// No description provided for @noLicenseInfo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无许可证信息'**
  String get noLicenseInfo;

  /// No description provided for @noMoreContent.
  ///
  /// In zh_Hans, this message translates to:
  /// **'没有更多了'**
  String get noMoreContent;

  /// No description provided for @reload.
  ///
  /// In zh_Hans, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @todayBroadcast.
  ///
  /// In zh_Hans, this message translates to:
  /// **'今日放送'**
  String get todayBroadcast;

  /// No description provided for @back.
  ///
  /// In zh_Hans, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @monday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周一'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周二'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周三'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周四'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周五'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周六'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周日'**
  String get sunday;

  /// No description provided for @releaseCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}部'**
  String releaseCount(Object count);

  /// No description provided for @noUpdatesOnWeekday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{weekday}无番剧更新'**
  String noUpdatesOnWeekday(Object weekday);

  /// No description provided for @animeCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'番剧数量'**
  String get animeCount;

  /// No description provided for @totalWatchers.
  ///
  /// In zh_Hans, this message translates to:
  /// **'总观看人数'**
  String get totalWatchers;

  /// No description provided for @averageRating.
  ///
  /// In zh_Hans, this message translates to:
  /// **'平均评分'**
  String get averageRating;

  /// No description provided for @calendarSummary.
  ///
  /// In zh_Hans, this message translates to:
  /// **'周{weekday}上映{releases}部,总{viewers}人收看'**
  String calendarSummary(Object weekday, Object releases, Object viewers);

  /// No description provided for @noUpdatesToday.
  ///
  /// In zh_Hans, this message translates to:
  /// **'今日无番剧更新'**
  String get noUpdatesToday;

  /// No description provided for @forumUnderConstruction.
  ///
  /// In zh_Hans, this message translates to:
  /// **'施工中...'**
  String get forumUnderConstruction;

  /// No description provided for @rankingTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'排行榜'**
  String get rankingTitle;

  /// No description provided for @allYears.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全部年份'**
  String get allYears;

  /// No description provided for @allMonths.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全部月份'**
  String get allMonths;

  /// No description provided for @all.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @yearSuffix.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{year}年'**
  String yearSuffix(Object year);

  /// No description provided for @monthSuffix.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{month}月'**
  String monthSuffix(Object month);

  /// No description provided for @sortRank.
  ///
  /// In zh_Hans, this message translates to:
  /// **'排名'**
  String get sortRank;

  /// No description provided for @sortTrends.
  ///
  /// In zh_Hans, this message translates to:
  /// **'热门'**
  String get sortTrends;

  /// No description provided for @sortCollects.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收藏'**
  String get sortCollects;

  /// No description provided for @sortDate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'日期'**
  String get sortDate;

  /// No description provided for @sortTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'名称'**
  String get sortTitle;

  /// No description provided for @rankingNoData.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无数据'**
  String get rankingNoData;

  /// No description provided for @rankingEnd.
  ///
  /// In zh_Hans, this message translates to:
  /// **'到底了'**
  String get rankingEnd;

  /// No description provided for @rankingLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载失败: {error}'**
  String rankingLoadFailed(Object error);

  /// No description provided for @retry.
  ///
  /// In zh_Hans, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @summaryTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'简介'**
  String get summaryTitle;

  /// No description provided for @tagsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'标签'**
  String get tagsTitle;

  /// No description provided for @detailsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'详情'**
  String get detailsTitle;

  /// No description provided for @charactersTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'角色'**
  String get charactersTitle;

  /// No description provided for @charactersLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载角色信息失败'**
  String get charactersLoadFailed;

  /// No description provided for @noCharacters.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无角色信息'**
  String get noCharacters;

  /// No description provided for @characterWorks.
  ///
  /// In zh_Hans, this message translates to:
  /// **'出演'**
  String get characterWorks;

  /// No description provided for @backToTop.
  ///
  /// In zh_Hans, this message translates to:
  /// **'返回顶部'**
  String get backToTop;

  /// No description provided for @noComments.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无吐槽'**
  String get noComments;

  /// No description provided for @characterWorksLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载出演作品失败'**
  String get characterWorksLoadFailed;

  /// No description provided for @noCharacterWorks.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无出演作品'**
  String get noCharacterWorks;

  /// No description provided for @viewDetails.
  ///
  /// In zh_Hans, this message translates to:
  /// **'查看详情'**
  String get viewDetails;

  /// No description provided for @producersTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'制作人'**
  String get producersTitle;

  /// No description provided for @relatedTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'关联条目'**
  String get relatedTitle;

  /// No description provided for @commentsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'吐槽'**
  String get commentsTitle;

  /// No description provided for @episodeCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全{count}话'**
  String episodeCount(Object count);

  /// No description provided for @confirmAllWatched.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认全部已看'**
  String get confirmAllWatched;

  /// No description provided for @confirmAllWatchedMessage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定将该番剧的全部剧集标记为已看吗？'**
  String get confirmAllWatchedMessage;

  /// No description provided for @markAllWatchedSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已将全部剧集标记为已看'**
  String get markAllWatchedSuccess;

  /// No description provided for @loadedEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已加载 {count} 集'**
  String loadedEpisodes(Object count);

  /// No description provided for @allWatched.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全部已看'**
  String get allWatched;

  /// No description provided for @yourRating.
  ///
  /// In zh_Hans, this message translates to:
  /// **'你的评分:{rating}'**
  String yourRating(Object rating);

  /// No description provided for @ratingCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'({count})人评分'**
  String ratingCount(Object count);

  /// No description provided for @collectionCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}收藏/'**
  String collectionCount(Object count);

  /// No description provided for @watchingCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}再看/'**
  String watchingCount(Object count);

  /// No description provided for @droppedCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}抛弃'**
  String droppedCount(Object count);

  /// No description provided for @playIntroTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'简介'**
  String get playIntroTab;

  /// No description provided for @playCommentsTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'吐槽'**
  String get playCommentsTab;

  /// No description provided for @pleaseLogin.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请先登录'**
  String get pleaseLogin;

  /// No description provided for @loginBeforeDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请先登录后再发送弹幕'**
  String get loginBeforeDanmaku;

  /// No description provided for @tip.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提示'**
  String get tip;

  /// No description provided for @danmakuSent.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕发送成功'**
  String get danmakuSent;

  /// No description provided for @danmakuUnsupported.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前不支持发送弹幕'**
  String get danmakuUnsupported;

  /// No description provided for @episodeSelection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'选集'**
  String get episodeSelection;

  /// No description provided for @switchToList.
  ///
  /// In zh_Hans, this message translates to:
  /// **'切换到列表'**
  String get switchToList;

  /// No description provided for @switchToGrid.
  ///
  /// In zh_Hans, this message translates to:
  /// **'切换到网格'**
  String get switchToGrid;

  /// No description provided for @fetchingEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在获取剧集...'**
  String get fetchingEpisodes;

  /// No description provided for @episodeLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'剧集获取失败'**
  String get episodeLoadFailed;

  /// No description provided for @noEpisodeData.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无章节数据'**
  String get noEpisodeData;

  /// No description provided for @updatedProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已更新观看进度'**
  String get updatedProgress;

  /// No description provided for @updateFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新失败'**
  String get updateFailed;

  /// No description provided for @commentCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'评论数 {count}'**
  String commentCount(Object count);

  /// No description provided for @commentLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'评论加载失败'**
  String get commentLoadFailed;

  /// No description provided for @defaultSort.
  ///
  /// In zh_Hans, this message translates to:
  /// **'默认'**
  String get defaultSort;

  /// No description provided for @newestSort.
  ///
  /// In zh_Hans, this message translates to:
  /// **'最新'**
  String get newestSort;

  /// No description provided for @commentsAction.
  ///
  /// In zh_Hans, this message translates to:
  /// **'评论'**
  String get commentsAction;

  /// No description provided for @danmakuSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕源:'**
  String get danmakuSource;

  /// No description provided for @totalDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'总装填({count})条弹幕'**
  String totalDanmaku(Object count);

  /// No description provided for @switchDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'切换弹幕'**
  String get switchDanmaku;

  /// No description provided for @enterTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入标题'**
  String get enterTitle;

  /// No description provided for @searchResults.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索结果:'**
  String get searchResults;

  /// No description provided for @cancel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提交'**
  String get submit;

  /// No description provided for @noDanmakuEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无剧集数据'**
  String get noDanmakuEpisodes;

  /// No description provided for @close.
  ///
  /// In zh_Hans, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @videoSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据源'**
  String get videoSource;

  /// No description provided for @autoSelectingResource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动选择资源中'**
  String get autoSelectingResource;

  /// No description provided for @switchSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'切换源'**
  String get switchSource;

  /// No description provided for @sourceActions.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据源操作'**
  String get sourceActions;

  /// No description provided for @openPlaybackPage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'浏览器播放页面'**
  String get openPlaybackPage;

  /// No description provided for @copySourceLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'复制数据源链接'**
  String get copySourceLink;

  /// No description provided for @copied.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @sourceLinkCopied.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据源链接已复制'**
  String get sourceLinkCopied;

  /// No description provided for @lineLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'线路: {line}'**
  String lineLabel(Object line);

  /// No description provided for @recommendationsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'相关推荐'**
  String get recommendationsTitle;

  /// No description provided for @recommendationLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'推荐数据获取失败'**
  String get recommendationLoadFailed;

  /// No description provided for @videoSettingsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'视频设置'**
  String get videoSettingsTitle;

  /// No description provided for @scheduledOff.
  ///
  /// In zh_Hans, this message translates to:
  /// **'定时关闭'**
  String get scheduledOff;

  /// No description provided for @minutesUnit.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}分钟'**
  String minutesUnit(Object count);

  /// No description provided for @hoursUnit.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{count}小时'**
  String hoursUnit(Object count);

  /// No description provided for @hoursMinutesUnit.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{hours}小时{minutes}分钟'**
  String hoursMinutesUnit(Object hours, Object minutes);

  /// No description provided for @confirm.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @moreSettingsBuilding.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更多设置正在施工中...'**
  String get moreSettingsBuilding;

  /// No description provided for @exitFullscreen.
  ///
  /// In zh_Hans, this message translates to:
  /// **'退出全屏'**
  String get exitFullscreen;

  /// No description provided for @skipSeconds.
  ///
  /// In zh_Hans, this message translates to:
  /// **'跳过{seconds}秒'**
  String skipSeconds(Object seconds);

  /// No description provided for @settings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @turnOffDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'关闭弹幕'**
  String get turnOffDanmaku;

  /// No description provided for @turnOnDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开启弹幕'**
  String get turnOnDanmaku;

  /// No description provided for @danmakuSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕设置'**
  String get danmakuSettings;

  /// No description provided for @loginToSendDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录后才能发送弹幕'**
  String get loginToSendDanmaku;

  /// No description provided for @pause.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @nextEpisode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下一集'**
  String get nextEpisode;

  /// No description provided for @playbackRate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'倍速'**
  String get playbackRate;

  /// No description provided for @sendDanmakuHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'发送弹幕...'**
  String get sendDanmakuHint;

  /// No description provided for @waitToSendDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请等待{seconds}秒后再发…'**
  String waitToSendDanmaku(Object seconds);

  /// No description provided for @collectionPlanToWatch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'想看'**
  String get collectionPlanToWatch;

  /// No description provided for @collectionWatched.
  ///
  /// In zh_Hans, this message translates to:
  /// **'看过'**
  String get collectionWatched;

  /// No description provided for @collectionWatching.
  ///
  /// In zh_Hans, this message translates to:
  /// **'在看'**
  String get collectionWatching;

  /// No description provided for @collectionOnHold.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搁置'**
  String get collectionOnHold;

  /// No description provided for @collectionAbandoned.
  ///
  /// In zh_Hans, this message translates to:
  /// **'抛弃'**
  String get collectionAbandoned;

  /// No description provided for @collectionLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收藏'**
  String get collectionLabel;

  /// No description provided for @searchCollection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索收藏'**
  String get searchCollection;

  /// No description provided for @collectionKeywordHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'输入收藏关键词'**
  String get collectionKeywordHint;

  /// No description provided for @search.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @imageSearch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图片搜索'**
  String get imageSearch;

  /// No description provided for @switchToUploadImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'改为上传图片文件'**
  String get switchToUploadImage;

  /// No description provided for @switchToImageUrl.
  ///
  /// In zh_Hans, this message translates to:
  /// **'改为输入图片 URL'**
  String get switchToImageUrl;

  /// No description provided for @searching.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索中...'**
  String get searching;

  /// No description provided for @startSearch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开始搜索'**
  String get startSearch;

  /// No description provided for @tapToSelectImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'点击选择图片'**
  String get tapToSelectImage;

  /// No description provided for @supportedImageFormats.
  ///
  /// In zh_Hans, this message translates to:
  /// **'支持 JPG、PNG、WEBP 格式'**
  String get supportedImageFormats;

  /// No description provided for @imagePreviewFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图片预览失败'**
  String get imagePreviewFailed;

  /// No description provided for @imageSelected.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已选择图片'**
  String get imageSelected;

  /// No description provided for @tapToReselectImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'点击可重新选择图片'**
  String get tapToReselectImage;

  /// No description provided for @reselect.
  ///
  /// In zh_Hans, this message translates to:
  /// **'重新选择'**
  String get reselect;

  /// No description provided for @enterImageUrl.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入图片链接'**
  String get enterImageUrl;

  /// No description provided for @clear.
  ///
  /// In zh_Hans, this message translates to:
  /// **'清除'**
  String get clear;

  /// No description provided for @enterImageUrlToPreview.
  ///
  /// In zh_Hans, this message translates to:
  /// **'输入图片链接后预览'**
  String get enterImageUrlToPreview;

  /// No description provided for @imageLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图片加载失败'**
  String get imageLoadFailed;

  /// No description provided for @checkImageUrl.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请检查链接是否有效'**
  String get checkImageUrl;

  /// No description provided for @recognizingImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在识别图片'**
  String get recognizingImage;

  /// No description provided for @matchingAnimeFromImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请稍候，正在从截图中匹配番剧信息'**
  String get matchingAnimeFromImage;

  /// No description provided for @imageSearchResultPlaceholder.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索结果将在这里展示'**
  String get imageSearchResultPlaceholder;

  /// No description provided for @noImageSearchResults.
  ///
  /// In zh_Hans, this message translates to:
  /// **'未获取到搜索结果'**
  String get noImageSearchResults;

  /// No description provided for @startImageSearchHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'选择图片文件或输入图片链接后开始搜索'**
  String get startImageSearchHint;

  /// No description provided for @recognitionResults.
  ///
  /// In zh_Hans, this message translates to:
  /// **'识别结果'**
  String get recognitionResults;

  /// No description provided for @originalAspectRatioTip.
  ///
  /// In zh_Hans, this message translates to:
  /// **'仅支持使用原始比例番剧截图搜索结果'**
  String get originalAspectRatioTip;

  /// No description provided for @clearScreenshotTip.
  ///
  /// In zh_Hans, this message translates to:
  /// **'截图应清晰，避免过度压缩或添加水印'**
  String get clearScreenshotTip;

  /// No description provided for @searchEnginePoweredBy.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索引擎由 '**
  String get searchEnginePoweredBy;

  /// No description provided for @providesSupport.
  ///
  /// In zh_Hans, this message translates to:
  /// **' 提供支持'**
  String get providesSupport;

  /// No description provided for @searchAnimeByImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'以图搜番'**
  String get searchAnimeByImage;

  /// No description provided for @searchSuggestions.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索建议'**
  String get searchSuggestions;

  /// No description provided for @searchResultCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索到 {count} 条内容'**
  String searchResultCount(Object count);

  /// No description provided for @enterKeywordToSearch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'输入关键词开始搜索'**
  String get enterKeywordToSearch;

  /// No description provided for @searchHistory.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索历史'**
  String get searchHistory;

  /// No description provided for @clearAll.
  ///
  /// In zh_Hans, this message translates to:
  /// **'清除全部'**
  String get clearAll;

  /// No description provided for @delete.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @refreshFailedRetry.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新失败，请稍后重试'**
  String get refreshFailedRetry;

  /// No description provided for @noData.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @noMore.
  ///
  /// In zh_Hans, this message translates to:
  /// **'没有更多了'**
  String get noMore;

  /// No description provided for @loginToCollect.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录后收藏'**
  String get loginToCollect;

  /// No description provided for @collectionLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载失败，请稍后重试'**
  String get collectionLoadFailed;

  /// No description provided for @collectionLoadMoreFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载更多失败，请稍后重试'**
  String get collectionLoadMoreFailed;

  /// No description provided for @moreMenu.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更多菜单'**
  String get moreMenu;

  /// No description provided for @profileLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'获取用户资料失败'**
  String get profileLoadFailed;

  /// No description provided for @profileExpired.
  ///
  /// In zh_Hans, this message translates to:
  /// **'用户资料已失效'**
  String get profileExpired;

  /// No description provided for @noUserProfile.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无用户资料'**
  String get noUserProfile;

  /// No description provided for @confirmLogout.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认退出'**
  String get confirmLogout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定要退出登录吗？'**
  String get logoutConfirmation;

  /// No description provided for @logout.
  ///
  /// In zh_Hans, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @playbackHistory.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放记录'**
  String get playbackHistory;

  /// No description provided for @clearSearch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'清除搜索'**
  String get clearSearch;

  /// No description provided for @refreshCurrentTab.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新当前标签'**
  String get refreshCurrentTab;

  /// No description provided for @showUserInfo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'显示用户信息'**
  String get showUserInfo;

  /// No description provided for @hideUserInfo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'隐藏用户信息'**
  String get hideUserInfo;

  /// No description provided for @joinedDate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{date}加入'**
  String joinedDate(Object date);

  /// No description provided for @userInfoSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'用户信息'**
  String get userInfoSettings;

  /// No description provided for @accountSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'账户设置'**
  String get accountSettings;

  /// No description provided for @appAppearance.
  ///
  /// In zh_Hans, this message translates to:
  /// **'应用与外观'**
  String get appAppearance;

  /// No description provided for @themeStyle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'主题样式'**
  String get themeStyle;

  /// No description provided for @playbackResources.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放资源'**
  String get playbackResources;

  /// No description provided for @sourceManagement.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据源管理'**
  String get sourceManagement;

  /// No description provided for @playerSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放器设置'**
  String get playerSettings;

  /// No description provided for @playbackSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放'**
  String get playbackSettings;

  /// No description provided for @otherSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'其他'**
  String get otherSettings;

  /// No description provided for @about.
  ///
  /// In zh_Hans, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @errorLogs.
  ///
  /// In zh_Hans, this message translates to:
  /// **'错误日志'**
  String get errorLogs;

  /// No description provided for @errorLogsEmpty.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无日志'**
  String get errorLogsEmpty;

  /// No description provided for @errorLogsLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载日志失败'**
  String get errorLogsLoadFailed;

  /// No description provided for @errorLogsClear.
  ///
  /// In zh_Hans, this message translates to:
  /// **'清空日志'**
  String get errorLogsClear;

  /// No description provided for @errorLogsClearConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定要清空日志吗？'**
  String get errorLogsClearConfirmation;

  /// No description provided for @errorLogsCopy.
  ///
  /// In zh_Hans, this message translates to:
  /// **'复制日志'**
  String get errorLogsCopy;

  /// No description provided for @errorLogsCopied.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已复制到剪贴板'**
  String get errorLogsCopied;

  /// No description provided for @errorLogsCleared.
  ///
  /// In zh_Hans, this message translates to:
  /// **'日志已清空'**
  String get errorLogsCleared;

  /// No description provided for @errorLogsClearFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'清空日志失败'**
  String get errorLogsClearFailed;

  /// No description provided for @errorLogsCopyFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'复制日志失败'**
  String get errorLogsCopyFailed;

  /// No description provided for @errorLogsAnalyze.
  ///
  /// In zh_Hans, this message translates to:
  /// **'分析日志文件'**
  String get errorLogsAnalyze;

  /// No description provided for @errorLogsOpen.
  ///
  /// In zh_Hans, this message translates to:
  /// **'打开日志文件'**
  String get errorLogsOpen;

  /// No description provided for @errorLogsOpenFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'打开日志文件失败'**
  String get errorLogsOpenFailed;

  /// No description provided for @errorLogsShareFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'分享日志文件失败'**
  String get errorLogsShareFailed;

  /// No description provided for @themeMode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @darkMode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'深色护眼'**
  String get darkModeSubtitle;

  /// No description provided for @lightMode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// No description provided for @lightModeSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'明亮清爽'**
  String get lightModeSubtitle;

  /// No description provided for @followSystem.
  ///
  /// In zh_Hans, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @autoAdapt.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动适配'**
  String get autoAdapt;

  /// No description provided for @themeColor.
  ///
  /// In zh_Hans, this message translates to:
  /// **'主题颜色'**
  String get themeColor;

  /// No description provided for @fontStyle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'字体样式'**
  String get fontStyle;

  /// No description provided for @customAppFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自定义应用字体'**
  String get customAppFont;

  /// No description provided for @autoNextEpisode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动跳转下一集'**
  String get autoNextEpisode;

  /// No description provided for @autoNextEpisodeSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放完成后自动切换到下一集'**
  String get autoNextEpisodeSubtitle;

  /// No description provided for @adBlocker.
  ///
  /// In zh_Hans, this message translates to:
  /// **'过滤广告'**
  String get adBlocker;

  /// No description provided for @adBlockerSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'过滤视频中插入的广告切片'**
  String get adBlockerSubtitle;

  /// No description provided for @skipDuration.
  ///
  /// In zh_Hans, this message translates to:
  /// **'跳过时长（秒）'**
  String get skipDuration;

  /// No description provided for @skipDurationSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'用于跳过视频 OP/ED'**
  String get skipDurationSubtitle;

  /// No description provided for @seconds.
  ///
  /// In zh_Hans, this message translates to:
  /// **'秒'**
  String get seconds;

  /// No description provided for @playbackProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放进度'**
  String get playbackProgress;

  /// No description provided for @saveEpisodeProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'保存剧集进度'**
  String get saveEpisodeProgress;

  /// No description provided for @saveEpisodeProgressSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放至90%自动保存剧集进度，下次从未观看的剧集开始播放'**
  String get saveEpisodeProgressSubtitle;

  /// No description provided for @playbackControl.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放控制'**
  String get playbackControl;

  /// No description provided for @longPressFastForwardSpeed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'长按快进速度'**
  String get longPressFastForwardSpeed;

  /// No description provided for @danmakuDisplayType.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕显示类型'**
  String get danmakuDisplayType;

  /// No description provided for @danmakuChineseConversion.
  ///
  /// In zh_Hans, this message translates to:
  /// **'简繁转换'**
  String get danmakuChineseConversion;

  /// No description provided for @danmakuChineseNone.
  ///
  /// In zh_Hans, this message translates to:
  /// **'关闭'**
  String get danmakuChineseNone;

  /// No description provided for @danmakuChineseToTraditional.
  ///
  /// In zh_Hans, this message translates to:
  /// **'简体转繁体'**
  String get danmakuChineseToTraditional;

  /// No description provided for @danmakuChineseToSimplified.
  ///
  /// In zh_Hans, this message translates to:
  /// **'繁体转简体'**
  String get danmakuChineseToSimplified;

  /// No description provided for @scrollingDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'滚动弹幕'**
  String get scrollingDanmaku;

  /// No description provided for @topDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'顶部弹幕'**
  String get topDanmaku;

  /// No description provided for @bottomDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'底部弹幕'**
  String get bottomDanmaku;

  /// No description provided for @danmakuSourcePlatform.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕来源平台'**
  String get danmakuSourcePlatform;

  /// No description provided for @danmakuStyle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕样式'**
  String get danmakuStyle;

  /// No description provided for @showBorder.
  ///
  /// In zh_Hans, this message translates to:
  /// **'显示边框'**
  String get showBorder;

  /// No description provided for @showColor.
  ///
  /// In zh_Hans, this message translates to:
  /// **'显示颜色'**
  String get showColor;

  /// No description provided for @massiveMode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'密集模式'**
  String get massiveMode;

  /// No description provided for @danmakuSpeedTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕速度'**
  String get danmakuSpeedTitle;

  /// No description provided for @danmakuSpeed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'速度：{percent}%'**
  String danmakuSpeed(Object percent);

  /// No description provided for @opacity.
  ///
  /// In zh_Hans, this message translates to:
  /// **'透明度'**
  String get opacity;

  /// No description provided for @fontSize.
  ///
  /// In zh_Hans, this message translates to:
  /// **'字体大小'**
  String get fontSize;

  /// No description provided for @displayArea.
  ///
  /// In zh_Hans, this message translates to:
  /// **'显示区域'**
  String get displayArea;

  /// No description provided for @logoutSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已退出登录'**
  String get logoutSuccess;

  /// No description provided for @openAuthorizationFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'打开授权页面失败'**
  String get openAuthorizationFailed;

  /// No description provided for @loginStateLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载登录状态失败'**
  String get loginStateLoadFailed;

  /// No description provided for @notLoggedIn.
  ///
  /// In zh_Hans, this message translates to:
  /// **'尚未登录'**
  String get notLoggedIn;

  /// No description provided for @loginToManageAccount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录后可管理账户信息、绑定 Bangumi 账号'**
  String get loginToManageAccount;

  /// No description provided for @login.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @error.
  ///
  /// In zh_Hans, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @moreActions.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更多操作'**
  String get moreActions;

  /// No description provided for @unableOpenLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法打开链接'**
  String get unableOpenLink;

  /// No description provided for @websiteLinkCopied.
  ///
  /// In zh_Hans, this message translates to:
  /// **'网站链接已复制到剪贴板'**
  String get websiteLinkCopied;

  /// No description provided for @saveImageFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'保存图片失败: {error}'**
  String saveImageFailed(Object error);

  /// No description provided for @openInBrowser.
  ///
  /// In zh_Hans, this message translates to:
  /// **'浏览器查看'**
  String get openInBrowser;

  /// No description provided for @downloadCover.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载封面'**
  String get downloadCover;

  /// No description provided for @copyWebsite.
  ///
  /// In zh_Hans, this message translates to:
  /// **'复制网站'**
  String get copyWebsite;

  /// No description provided for @loginSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录成功'**
  String get loginSuccess;

  /// No description provided for @welcomeTo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'欢迎来到 '**
  String get welcomeTo;

  /// No description provided for @loginToManageCollection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录后进行收藏管理'**
  String get loginToManageCollection;

  /// No description provided for @email.
  ///
  /// In zh_Hans, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @password.
  ///
  /// In zh_Hans, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @enterEmail.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入邮箱'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入有效邮箱'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入密码'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In zh_Hans, this message translates to:
  /// **'密码至少需要 6 位'**
  String get passwordMinLength;

  /// No description provided for @showPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'显示密码'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'隐藏密码'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'忘记密码'**
  String get forgotPassword;

  /// No description provided for @loggingIn.
  ///
  /// In zh_Hans, this message translates to:
  /// **'登录中...'**
  String get loggingIn;

  /// No description provided for @bangumiAuthorizeLogin.
  ///
  /// In zh_Hans, this message translates to:
  /// **'Bangumi 授权登录'**
  String get bangumiAuthorizeLogin;

  /// No description provided for @bangumi.
  ///
  /// In zh_Hans, this message translates to:
  /// **'Bangumi'**
  String get bangumi;

  /// No description provided for @noAccount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'还没有账号？'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In zh_Hans, this message translates to:
  /// **'立即注册'**
  String get registerNow;

  /// No description provided for @authorizeLogin.
  ///
  /// In zh_Hans, this message translates to:
  /// **'授权登录'**
  String get authorizeLogin;

  /// No description provided for @registerAccount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'注册账号'**
  String get registerAccount;

  /// No description provided for @registerSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'注册成功'**
  String get registerSuccess;

  /// No description provided for @registerTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'注册'**
  String get registerTitle;

  /// No description provided for @createAccount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'创建账号'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加入 AnimeFlow，同步你的追番体验'**
  String get registerSubtitle;

  /// No description provided for @enterGraphicCaptcha.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请先填写图形验证码'**
  String get enterGraphicCaptcha;

  /// No description provided for @emailCodeSent.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证码已发送，请查收邮件'**
  String get emailCodeSent;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In zh_Hans, this message translates to:
  /// **'邮箱格式不正确'**
  String get invalidEmailFormat;

  /// No description provided for @confirmPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// No description provided for @passwordLengthRange.
  ///
  /// In zh_Hans, this message translates to:
  /// **'密码长度需在 6-30 位之间'**
  String get passwordLengthRange;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请再次输入密码'**
  String get enterConfirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'两次输入的密码不一致'**
  String get passwordMismatch;

  /// No description provided for @emailVerificationCode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'邮箱验证码'**
  String get emailVerificationCode;

  /// No description provided for @enterEmailCode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入邮箱验证码'**
  String get enterEmailCode;

  /// No description provided for @emailCodeLength.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证码为 6 位数字'**
  String get emailCodeLength;

  /// No description provided for @haveAccountBackToLogin.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已有账号？返回登录'**
  String get haveAccountBackToLogin;

  /// No description provided for @accountInfo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'账户信息'**
  String get accountInfo;

  /// No description provided for @thirdPartyAccounts.
  ///
  /// In zh_Hans, this message translates to:
  /// **'第三方账号'**
  String get thirdPartyAccounts;

  /// No description provided for @accountActions.
  ///
  /// In zh_Hans, this message translates to:
  /// **'账户操作'**
  String get accountActions;

  /// No description provided for @nicknameUpdated.
  ///
  /// In zh_Hans, this message translates to:
  /// **'昵称已更新'**
  String get nicknameUpdated;

  /// No description provided for @waitingBangumiAuthorization.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在等待 Bangumi 授权结果...'**
  String get waitingBangumiAuthorization;

  /// No description provided for @authorizing.
  ///
  /// In zh_Hans, this message translates to:
  /// **'授权中...'**
  String get authorizing;

  /// No description provided for @bound.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已绑定'**
  String get bound;

  /// No description provided for @unbound.
  ///
  /// In zh_Hans, this message translates to:
  /// **'未绑定'**
  String get unbound;

  /// No description provided for @loading.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @bindStatusLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'获取绑定状态失败'**
  String get bindStatusLoadFailed;

  /// No description provided for @bindBangumiHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'绑定 Bangumi 账号后可同步收藏等数据'**
  String get bindBangumiHint;

  /// No description provided for @bindBangumiAccount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'绑定 Bangumi 账号'**
  String get bindBangumiAccount;

  /// No description provided for @confirmUnbind.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认解绑'**
  String get confirmUnbind;

  /// No description provided for @unbindConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定要解绑 Bangumi 账号吗？解绑后可能影响部分功能。'**
  String get unbindConfirmation;

  /// No description provided for @confirmUnbindAction.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定解绑'**
  String get confirmUnbindAction;

  /// No description provided for @unbind.
  ///
  /// In zh_Hans, this message translates to:
  /// **'解绑'**
  String get unbind;

  /// No description provided for @bangumiBindSuccessHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'Bangumi 授权与绑定应可正常使用。'**
  String get bangumiBindSuccessHint;

  /// No description provided for @bangumiBindFailureHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'授权或绑定 Bangumi 时，建议开启 VPN 或代理后重试。'**
  String get bangumiBindFailureHint;

  /// No description provided for @version.
  ///
  /// In zh_Hans, this message translates to:
  /// **'版本 {version}'**
  String version(Object version);

  /// No description provided for @autoUpdate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动更新'**
  String get autoUpdate;

  /// No description provided for @checkUpdate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'检查更新'**
  String get checkUpdate;

  /// No description provided for @openSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开源地址'**
  String get openSource;

  /// No description provided for @unableOpenWeb.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法打开网页'**
  String get unableOpenWeb;

  /// No description provided for @deviceUnsupportedWeb.
  ///
  /// In zh_Hans, this message translates to:
  /// **'你的设备可能不支持此功能'**
  String get deviceUnsupportedWeb;

  /// No description provided for @thanks.
  ///
  /// In zh_Hans, this message translates to:
  /// **'鸣谢'**
  String get thanks;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh_Hans, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @specialThanks.
  ///
  /// In zh_Hans, this message translates to:
  /// **'特别鸣谢'**
  String get specialThanks;

  /// No description provided for @thanksDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'感谢以下优秀的开源项目和技术支持，让 AnimeFlow 变得更好'**
  String get thanksDescription;

  /// No description provided for @kazumiWebViewSupport.
  ///
  /// In zh_Hans, this message translates to:
  /// **'Kazumi 项目提供的 WebView 技术支持'**
  String get kazumiWebViewSupport;

  /// No description provided for @mediaKitDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'跨平台视频播放器，支持高质量视频播放'**
  String get mediaKitDescription;

  /// No description provided for @canvasDanmakuDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'弹幕插件，提供流畅的弹幕绘制'**
  String get canvasDanmakuDescription;

  /// No description provided for @dandanplayDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提供丰富的弹幕数据源'**
  String get dandanplayDescription;

  /// No description provided for @bangumiDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提供番剧信息和用户数据同步服务'**
  String get bangumiDescription;

  /// No description provided for @anime4kDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'超分辨率技术，提升视频画质'**
  String get anime4kDescription;

  /// No description provided for @traceMoeDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提供以图识别番功能'**
  String get traceMoeDescription;

  /// No description provided for @fontRefreshFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新失败：{error}'**
  String fontRefreshFailed(Object error);

  /// No description provided for @fontStylePageTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'字体样式'**
  String get fontStylePageTitle;

  /// No description provided for @refreshFontList.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新字体列表'**
  String get refreshFontList;

  /// No description provided for @fontLibrary.
  ///
  /// In zh_Hans, this message translates to:
  /// **'字体库'**
  String get fontLibrary;

  /// No description provided for @cdnAcceleration.
  ///
  /// In zh_Hans, this message translates to:
  /// **'CDN 加速'**
  String get cdnAcceleration;

  /// No description provided for @fontDelayHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'新上架的字体可能会延迟显示'**
  String get fontDelayHint;

  /// No description provided for @cdnTooltip.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开启：经 jsDelivr 拉取字体；关闭：直连 GitHub Raw（走镜像）'**
  String get cdnTooltip;

  /// No description provided for @fontRestartHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'如果字体效果没有完全显示请重启应用'**
  String get fontRestartHint;

  /// No description provided for @noOtherFonts.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无其他可用字体'**
  String get noOtherFonts;

  /// No description provided for @downloadedOrphanFonts.
  ///
  /// In zh_Hans, this message translates to:
  /// **'本地已下载（远程已下架）'**
  String get downloadedOrphanFonts;

  /// No description provided for @orphanFontDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'以下字体不再出现在远程仓库，但本地仍保留有字体文件。可在此处直接删除或继续应用。'**
  String get orphanFontDescription;

  /// No description provided for @fontListLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载字体列表失败'**
  String get fontListLoadFailed;

  /// No description provided for @systemFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'跟随系统'**
  String get systemFont;

  /// No description provided for @systemFontSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'使用系统默认字体'**
  String get systemFontSubtitle;

  /// No description provided for @fontAuthorInfo.
  ///
  /// In zh_Hans, this message translates to:
  /// **'作者：{author} - 字体包体积：{size}'**
  String fontAuthorInfo(Object author, Object size);

  /// No description provided for @downloadFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载字体'**
  String get downloadFont;

  /// No description provided for @appliedFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已应用，点击取消使用'**
  String get appliedFont;

  /// No description provided for @applyFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'点击应用此字体'**
  String get applyFont;

  /// No description provided for @deleteDownloadedFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除已下载字体'**
  String get deleteDownloadedFont;

  /// No description provided for @downloadFontFailedRetry.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载失败，点击重试'**
  String get downloadFontFailedRetry;

  /// No description provided for @deleteFont.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除字体'**
  String get deleteFont;

  /// No description provided for @deleteSelectedFontConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'将删除「{fontName}」的本地文件，并恢复为系统字体，确定继续？'**
  String deleteSelectedFontConfirmation(Object fontName);

  /// No description provided for @deleteFontConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定删除「{fontName}」的本地字体文件？'**
  String deleteFontConfirmation(Object fontName);

  /// No description provided for @previewLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'预览加载失败'**
  String get previewLoadFailed;

  /// No description provided for @fontPreviewHeadline.
  ///
  /// In zh_Hans, this message translates to:
  /// **'欢迎使用 AnimeFlow'**
  String get fontPreviewHeadline;

  /// No description provided for @orphanFontAvailable.
  ///
  /// In zh_Hans, this message translates to:
  /// **'远程仓库已下架，仍可继续使用本地字体'**
  String get orphanFontAvailable;

  /// No description provided for @orphanFontMissing.
  ///
  /// In zh_Hans, this message translates to:
  /// **'本地字体文件已丢失，可在此处清理记录'**
  String get orphanFontMissing;

  /// No description provided for @confirmDelete.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @deleteSourceConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定要删除数据源 \"{name}\" 吗？此操作不可恢复。'**
  String deleteSourceConfirmation(Object name);

  /// No description provided for @deleteSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除成功'**
  String get deleteSuccess;

  /// No description provided for @deleteFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除失败'**
  String get deleteFailed;

  /// No description provided for @sourceDeleted.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据源 \"{name}\" 已被删除'**
  String sourceDeleted(Object name);

  /// No description provided for @sourceDeleteFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除数据源 \"{name}\" 时发生错误：{error}'**
  String sourceDeleteFailed(Object error, Object name);

  /// No description provided for @downloadConfig.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载配置'**
  String get downloadConfig;

  /// No description provided for @addSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'添加数据源'**
  String get addSource;

  /// No description provided for @editSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'编辑数据源'**
  String get editSource;

  /// No description provided for @saveFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'保存失败'**
  String get saveFailed;

  /// No description provided for @dataSaveFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'数据保存失败：{error}'**
  String dataSaveFailed(Object error);

  /// No description provided for @fieldRequired.
  ///
  /// In zh_Hans, this message translates to:
  /// **'此字段不能为空'**
  String get fieldRequired;

  /// No description provided for @versionNumber.
  ///
  /// In zh_Hans, this message translates to:
  /// **'版本号'**
  String get versionNumber;

  /// No description provided for @versionExample.
  ///
  /// In zh_Hans, this message translates to:
  /// **'如（1.0.0）'**
  String get versionExample;

  /// No description provided for @sourceName.
  ///
  /// In zh_Hans, this message translates to:
  /// **'名称'**
  String get sourceName;

  /// No description provided for @sourceNameHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'网站名称，唯一值避免与其他配置名称重复，否则将被覆盖'**
  String get sourceNameHint;

  /// No description provided for @iconLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图标链接'**
  String get iconLink;

  /// No description provided for @websiteLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'网站链接'**
  String get websiteLink;

  /// No description provided for @websiteLinkHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'网站主链接，避免以 / 结尾'**
  String get websiteLinkHint;

  /// No description provided for @searchLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索链接'**
  String get searchLink;

  /// No description provided for @searchLinkHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'用{keyword}搜索关键字，示例：https://dm.xifanacg.com/search.html?wd={keyword}'**
  String searchLinkHint(Object keyword);

  /// No description provided for @searchContentList.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索内容列表'**
  String get searchContentList;

  /// No description provided for @searchListName.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索列表名称'**
  String get searchListName;

  /// No description provided for @searchListLink.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索列表链接'**
  String get searchListLink;

  /// No description provided for @lineName.
  ///
  /// In zh_Hans, this message translates to:
  /// **'线路名称'**
  String get lineName;

  /// No description provided for @episodeList.
  ///
  /// In zh_Hans, this message translates to:
  /// **'剧集列表'**
  String get episodeList;

  /// No description provided for @episode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'剧集'**
  String get episode;

  /// No description provided for @episodeHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'剧集链接，从剧集列表中获取的数据的 XPath'**
  String get episodeHint;

  /// No description provided for @antiCrawlerOptional.
  ///
  /// In zh_Hans, this message translates to:
  /// **'反爬 / 验证码（可选）'**
  String get antiCrawlerOptional;

  /// No description provided for @enableWebViewCaptcha.
  ///
  /// In zh_Hans, this message translates to:
  /// **'启用 WebView 验证码处理'**
  String get enableWebViewCaptcha;

  /// No description provided for @webViewCaptchaSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'搜索触发验证码时，用 WebView 完成验证并保存 Cookie'**
  String get webViewCaptchaSubtitle;

  /// No description provided for @captchaType.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证类型'**
  String get captchaType;

  /// No description provided for @imageCaptchaManual.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图片验证码（手动输入）'**
  String get imageCaptchaManual;

  /// No description provided for @autoClickCaptcha.
  ///
  /// In zh_Hans, this message translates to:
  /// **'自动点击验证按钮'**
  String get autoClickCaptcha;

  /// No description provided for @captchaImageXPath.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证码图片 XPath'**
  String get captchaImageXPath;

  /// No description provided for @captchaImageXPathHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'WebView 内定位验证码图片元素'**
  String get captchaImageXPathHint;

  /// No description provided for @captchaInputXPath.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证码输入框 XPath'**
  String get captchaInputXPath;

  /// No description provided for @captchaInputXPathHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'供用户输入验证码的 input 元素'**
  String get captchaInputXPathHint;

  /// No description provided for @submitCaptchaXPath.
  ///
  /// In zh_Hans, this message translates to:
  /// **'提交验证码按钮 XPath'**
  String get submitCaptchaXPath;

  /// No description provided for @verifyButtonXPath.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证按钮 XPath'**
  String get verifyButtonXPath;

  /// No description provided for @submitCaptchaHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'点击后提交验证码的按钮'**
  String get submitCaptchaHint;

  /// No description provided for @autoClickCaptchaHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'检测到后自动点击的验证按钮（如「我不是机器人」）'**
  String get autoClickCaptchaHint;

  /// No description provided for @downloadSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载成功'**
  String get downloadSuccess;

  /// No description provided for @pluginDownloaded.
  ///
  /// In zh_Hans, this message translates to:
  /// **'插件 \"{name}\" 已下载'**
  String pluginDownloaded(Object name);

  /// No description provided for @pluginDownloadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载插件 \"{name}\" 时发生错误：{error}'**
  String pluginDownloadFailed(Object error, Object name);

  /// No description provided for @updateSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新成功'**
  String get updateSuccess;

  /// No description provided for @pluginUpdated.
  ///
  /// In zh_Hans, this message translates to:
  /// **'插件 \"{name}\" 已更新到版本 {version}'**
  String pluginUpdated(Object name, Object version);

  /// No description provided for @pluginUpdateFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新插件 \"{name}\" 时发生错误：{error}'**
  String pluginUpdateFailed(Object error, Object name);

  /// No description provided for @downloadSources.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载数据源'**
  String get downloadSources;

  /// No description provided for @downloadSourcesSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前会从 GitHub 仓库中下载数据源，注意网络环境，下拉刷新数据'**
  String get downloadSourcesSubtitle;

  /// No description provided for @useMirror.
  ///
  /// In zh_Hans, this message translates to:
  /// **'使用镜像'**
  String get useMirror;

  /// No description provided for @useMirrorSubtitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法直连 GitHub 时开启，通过镜像拉取插件列表'**
  String get useMirrorSubtitle;

  /// No description provided for @noDataRefresh.
  ///
  /// In zh_Hans, this message translates to:
  /// **'没有找到数据，请刷新'**
  String get noDataRefresh;

  /// No description provided for @downloaded.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已下载'**
  String get downloaded;

  /// No description provided for @updating.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新中…'**
  String get updating;

  /// No description provided for @update.
  ///
  /// In zh_Hans, this message translates to:
  /// **'更新'**
  String get update;

  /// No description provided for @pluginVersionDate.
  ///
  /// In zh_Hans, this message translates to:
  /// **'版本：{version} - {date}'**
  String pluginVersionDate(Object date, Object version);

  /// No description provided for @collectionSyncTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收藏同步'**
  String get collectionSyncTitle;

  /// No description provided for @collectionSyncStarted.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收藏同步已开始'**
  String get collectionSyncStarted;

  /// No description provided for @syncStartFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'启动同步失败'**
  String get syncStartFailed;

  /// No description provided for @refreshStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新状态'**
  String get refreshStatus;

  /// No description provided for @refreshStatusFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'刷新状态失败'**
  String get refreshStatusFailed;

  /// No description provided for @syncedItems.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已同步 {count} 条'**
  String syncedItems(Object count);

  /// No description provided for @syncInProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同步进行中…'**
  String get syncInProgress;

  /// No description provided for @manualSync.
  ///
  /// In zh_Hans, this message translates to:
  /// **'手动同步'**
  String get manualSync;

  /// No description provided for @syncBangumiCollection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同步 Bangumi 收藏'**
  String get syncBangumiCollection;

  /// No description provided for @syncStatusLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'获取同步状态失败'**
  String get syncStatusLoadFailed;

  /// No description provided for @syncStatusIdle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'未同步'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusRunning.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同步中'**
  String get syncStatusRunning;

  /// No description provided for @syncStatusSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同步完成'**
  String get syncStatusSuccess;

  /// No description provided for @syncStatusFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同步失败'**
  String get syncStatusFailed;

  /// No description provided for @introduction.
  ///
  /// In zh_Hans, this message translates to:
  /// **'介绍'**
  String get introduction;

  /// No description provided for @collection.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收藏'**
  String get collection;

  /// No description provided for @timeline.
  ///
  /// In zh_Hans, this message translates to:
  /// **'时间线'**
  String get timeline;

  /// No description provided for @userInfoUnavailable.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法查询到用户信息'**
  String get userInfoUnavailable;

  /// No description provided for @timelineComingSoon.
  ///
  /// In zh_Hans, this message translates to:
  /// **'时间线功能待实现'**
  String get timelineComingSoon;

  /// No description provided for @statistics.
  ///
  /// In zh_Hans, this message translates to:
  /// **'统计'**
  String get statistics;

  /// No description provided for @bio.
  ///
  /// In zh_Hans, this message translates to:
  /// **'个人简介'**
  String get bio;

  /// No description provided for @location.
  ///
  /// In zh_Hans, this message translates to:
  /// **'所在地'**
  String get location;

  /// No description provided for @website.
  ///
  /// In zh_Hans, this message translates to:
  /// **'网站'**
  String get website;

  /// No description provided for @mysteriousUser.
  ///
  /// In zh_Hans, this message translates to:
  /// **'该用户很神秘'**
  String get mysteriousUser;

  /// No description provided for @manualSearch.
  ///
  /// In zh_Hans, this message translates to:
  /// **'手动搜索'**
  String get manualSearch;

  /// No description provided for @manualSearchResource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'手动搜索资源'**
  String get manualSearchResource;

  /// No description provided for @fetchingResource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在获取 {website} 的资源'**
  String fetchingResource(Object website);

  /// No description provided for @reSearchingResource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前站点正在重新检索，请稍候片刻。'**
  String get reSearchingResource;

  /// No description provided for @resourceRequestFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{website} 请求失败'**
  String resourceRequestFailed(Object website);

  /// No description provided for @resourceNotFoundForSite.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{website} 暂未搜到资源'**
  String resourceNotFoundForSite(Object website);

  /// No description provided for @noPlayableSourceHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'没有检索到可用播放源。你可以稍后重试，或切换其他站点。'**
  String get noPlayableSourceHint;

  /// No description provided for @searchAgain.
  ///
  /// In zh_Hans, this message translates to:
  /// **'重新搜索'**
  String get searchAgain;

  /// No description provided for @unnamedLine.
  ///
  /// In zh_Hans, this message translates to:
  /// **'未命名线路'**
  String get unnamedLine;

  /// No description provided for @descending.
  ///
  /// In zh_Hans, this message translates to:
  /// **'倒序'**
  String get descending;

  /// No description provided for @ascending.
  ///
  /// In zh_Hans, this message translates to:
  /// **'升序'**
  String get ascending;

  /// No description provided for @lineFilter.
  ///
  /// In zh_Hans, this message translates to:
  /// **'线路筛选'**
  String get lineFilter;

  /// No description provided for @allLines.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全部线路'**
  String get allLines;

  /// No description provided for @currentEpisodeCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前集({count})'**
  String currentEpisodeCount(Object count);

  /// No description provided for @allEpisodesCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'全集({count})'**
  String allEpisodesCount(Object count);

  /// No description provided for @noPlayableSourceForEpisode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前剧集暂无可用播放源'**
  String get noPlayableSourceForEpisode;

  /// No description provided for @episodeNotInResultsHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前选中剧集不在这些结果里。你可以切到“全部集数”手动指定资源站集数。'**
  String get episodeNotInResultsHint;

  /// No description provided for @episodeNoSourceHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前剧集没有匹配到对应播放源。'**
  String get episodeNoSourceHint;

  /// No description provided for @noSelectableEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无可选集数'**
  String get noSelectableEpisodes;

  /// No description provided for @siteNoEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前站点没有返回可用播放集数。'**
  String get siteNoEpisodes;

  /// No description provided for @videoSourceLoadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'获取视频源失败: {error}'**
  String videoSourceLoadFailed(Object error);

  /// No description provided for @matchLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'匹配度:'**
  String get matchLabel;

  /// No description provided for @verificationSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证成功'**
  String get verificationSuccess;

  /// No description provided for @verificationRetrying.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在重新检索，请稍候…'**
  String get verificationRetrying;

  /// No description provided for @enterCaptcha.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入验证码'**
  String get enterCaptcha;

  /// No description provided for @captchaMayBeWrong.
  ///
  /// In zh_Hans, this message translates to:
  /// **'验证码可能有误，请重新输入'**
  String get captchaMayBeWrong;

  /// No description provided for @siteRequiresCaptcha.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{website} 需要验证码验证'**
  String siteRequiresCaptcha(Object website);

  /// No description provided for @verify.
  ///
  /// In zh_Hans, this message translates to:
  /// **'进行验证'**
  String get verify;

  /// No description provided for @siteAutoVerifying.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{website} 正在自动完成验证，请稍候'**
  String siteAutoVerifying(Object website);

  /// No description provided for @captchaVerification.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{website} 验证码验证'**
  String captchaVerification(Object website);

  /// No description provided for @loadingCaptchaImage.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在加载验证码图片...'**
  String get loadingCaptchaImage;

  /// No description provided for @imageDecodeFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'图片解码失败'**
  String get imageDecodeFailed;

  /// No description provided for @episodeNumber.
  ///
  /// In zh_Hans, this message translates to:
  /// **'第{episode}集'**
  String episodeNumber(Object episode);

  /// No description provided for @watchedLabel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'观看{progress}'**
  String watchedLabel(Object progress);

  /// No description provided for @playEpisode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'{episode}'**
  String playEpisode(Object episode);

  /// No description provided for @downloadsTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载管理'**
  String get downloadsTitle;

  /// No description provided for @downloadTasksEmpty.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无下载任务'**
  String get downloadTasksEmpty;

  /// No description provided for @downloadSelectionTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载选集'**
  String get downloadSelectionTitle;

  /// No description provided for @downloadResources.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载资源'**
  String get downloadResources;

  /// No description provided for @downloadSettings.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载设置'**
  String get downloadSettings;

  /// No description provided for @downloadLocation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'资源下载位置'**
  String get downloadLocation;

  /// No description provided for @downloadLocationUnavailable.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无法获取下载位置'**
  String get downloadLocationUnavailable;

  /// No description provided for @downloadLocationSelect.
  ///
  /// In zh_Hans, this message translates to:
  /// **'选择下载位置'**
  String get downloadLocationSelect;

  /// No description provided for @downloadLocationUnsupported.
  ///
  /// In zh_Hans, this message translates to:
  /// **'当前设备不支持自定义下载位置'**
  String get downloadLocationUnsupported;

  /// No description provided for @downloadDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同时下载弹幕'**
  String get downloadDanmaku;

  /// No description provided for @downloadDanmakuDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载完成后保存本地弹幕，失败不影响视频'**
  String get downloadDanmakuDescription;

  /// No description provided for @downloadParallelEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同时下载剧集数'**
  String get downloadParallelEpisodes;

  /// No description provided for @downloadParallelEpisodesDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'同时下载的剧集数量'**
  String get downloadParallelEpisodesDescription;

  /// No description provided for @downloadParallelSegments.
  ///
  /// In zh_Hans, this message translates to:
  /// **'分片并发数'**
  String get downloadParallelSegments;

  /// No description provided for @downloadParallelSegmentsDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'单集同时下载的视频分片数量'**
  String get downloadParallelSegmentsDescription;

  /// No description provided for @downloadWithDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'含弹幕'**
  String get downloadWithDanmaku;

  /// No description provided for @downloadWithoutDanmaku.
  ///
  /// In zh_Hans, this message translates to:
  /// **'无弹幕'**
  String get downloadWithoutDanmaku;

  /// No description provided for @expandDownloadEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'展开剧集'**
  String get expandDownloadEpisodes;

  /// No description provided for @collapseDownloadEpisodes.
  ///
  /// In zh_Hans, this message translates to:
  /// **'收起剧集'**
  String get collapseDownloadEpisodes;

  /// No description provided for @selectedEpisodesCount.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已选 {count} 集'**
  String selectedEpisodesCount(Object count);

  /// No description provided for @startDownload.
  ///
  /// In zh_Hans, this message translates to:
  /// **'开始下载'**
  String get startDownload;

  /// No description provided for @deleteDownloadTask.
  ///
  /// In zh_Hans, this message translates to:
  /// **'删除下载任务'**
  String get deleteDownloadTask;

  /// No description provided for @deleteDownloadTaskConfirmation.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确定删除「{episode}」的下载资源吗？'**
  String deleteDownloadTaskConfirmation(Object episode);

  /// No description provided for @downloadTaskProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已完成 {completed}/{total}'**
  String downloadTaskProgress(Object completed, Object total);

  /// No description provided for @downloadQueued.
  ///
  /// In zh_Hans, this message translates to:
  /// **'排队中'**
  String get downloadQueued;

  /// No description provided for @downloadResolving.
  ///
  /// In zh_Hans, this message translates to:
  /// **'解析中'**
  String get downloadResolving;

  /// No description provided for @downloadDownloadingStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'下载中'**
  String get downloadDownloadingStatus;

  /// No description provided for @downloadCompletedStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已完成'**
  String get downloadCompletedStatus;

  /// No description provided for @downloadFailedStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已失败'**
  String get downloadFailedStatus;

  /// No description provided for @downloadPausedStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已暂停'**
  String get downloadPausedStatus;

  /// No description provided for @resetPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'重置密码'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// No description provided for @emailCode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'邮箱验证码'**
  String get emailCode;

  /// No description provided for @backToLogin.
  ///
  /// In zh_Hans, this message translates to:
  /// **'返回登录'**
  String get backToLogin;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In zh_Hans, this message translates to:
  /// **'通过邮箱验证码重置登录密码，每个邮箱每天仅可重置一次'**
  String get resetPasswordDescription;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In zh_Hans, this message translates to:
  /// **'密码重置成功，请使用新密码登录'**
  String get passwordResetSuccess;

  /// No description provided for @enterNewPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请输入新密码'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'确认新密码'**
  String get confirmNewPassword;

  /// No description provided for @enterConfirmNewPassword.
  ///
  /// In zh_Hans, this message translates to:
  /// **'请再次输入新密码'**
  String get enterConfirmNewPassword;

  /// No description provided for @sendEmailCode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'发送验证码'**
  String get sendEmailCode;

  /// No description provided for @enterGraphicCaptchaCode.
  ///
  /// In zh_Hans, this message translates to:
  /// **'输入6位验证码'**
  String get enterGraphicCaptchaCode;

  /// No description provided for @downloadNotificationTitle.
  ///
  /// In zh_Hans, this message translates to:
  /// **'AnimeFlow 下载'**
  String get downloadNotificationTitle;

  /// No description provided for @downloadNotificationStatus.
  ///
  /// In zh_Hans, this message translates to:
  /// **'正在下载 {active} 个任务 · 已完成 {completed}/{total} · {speed}'**
  String downloadNotificationStatus(
      Object active, Object completed, Object total, Object speed);

  /// No description provided for @downloadPauseAll.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂停全部'**
  String get downloadPauseAll;

  /// No description provided for @downloadSizeProgress.
  ///
  /// In zh_Hans, this message translates to:
  /// **'已下载 {downloaded} / 总大小 {total}'**
  String downloadSizeProgress(Object downloaded, Object total);

  /// No description provided for @playerKernel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放器内核'**
  String get playerKernel;

  /// No description provided for @selectPlayerKernel.
  ///
  /// In zh_Hans, this message translates to:
  /// **'选择播放器内核'**
  String get selectPlayerKernel;

  /// No description provided for @playerKernelTroubleshootingHint.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放页无法播放或发生闪退时，可尝试切换播放器内核。iOS 巨魔安装环境下，MediaKit 内核可能闪退，可切换至 FVP。'**
  String get playerKernelTroubleshootingHint;

  /// No description provided for @playerKernelSupportsSuperResolution.
  ///
  /// In zh_Hans, this message translates to:
  /// **'MediaKit 支持 Anime4K 等 GLSL 超分辨率 Shader'**
  String get playerKernelSupportsSuperResolution;

  /// No description provided for @playerKernelNoSuperResolution.
  ///
  /// In zh_Hans, this message translates to:
  /// **'FVP 不支持 Anime4K 等 GLSL 超分辨率 Shader'**
  String get playerKernelNoSuperResolution;

  /// No description provided for @playerKernelSwitchFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放器内核切换失败'**
  String get playerKernelSwitchFailed;

  /// No description provided for @mediaKit.
  ///
  /// In zh_Hans, this message translates to:
  /// **'MediaKit'**
  String get mediaKit;

  /// No description provided for @fvp.
  ///
  /// In zh_Hans, this message translates to:
  /// **'FVP'**
  String get fvp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hant_HK':
      return AppLocalizationsZhHantHk();
    case 'zh_Hant_TW':
      return AppLocalizationsZhHantTw();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
