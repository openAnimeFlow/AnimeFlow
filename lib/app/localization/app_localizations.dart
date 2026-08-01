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

  /// No description provided for @loadFailed.
  ///
  /// In zh_Hans, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

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

  /// No description provided for @noComments.
  ///
  /// In zh_Hans, this message translates to:
  /// **'暂无评论'**
  String get noComments;

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

  /// No description provided for @back.
  ///
  /// In zh_Hans, this message translates to:
  /// **'返回'**
  String get back;

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

  /// No description provided for @playbackHistoryVideoSource.
  ///
  /// In zh_Hans, this message translates to:
  /// **'播放历史与视频源'**
  String get playbackHistoryVideoSource;

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
