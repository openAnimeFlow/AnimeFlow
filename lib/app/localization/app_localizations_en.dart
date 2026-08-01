// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get generalSettingsTitle => 'General Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get selectLanguageTooltip => 'Select language';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get traditionalChineseTaiwan => 'Traditional Chinese (Taiwan)';

  @override
  String get traditionalChineseHongKong => 'Traditional Chinese (Hong Kong)';

  @override
  String get englishLanguage => 'English';

  @override
  String get recommendTab => 'Recommended';

  @override
  String get rankingTab => 'Ranking';

  @override
  String get mineTab => 'Mine';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get animeTab => 'Anime';

  @override
  String get forumTab => 'Forum';

  @override
  String get searchAnimeHint => 'Search anime...';

  @override
  String get playHistorySection => 'Play History';

  @override
  String get viewMore => 'View More';

  @override
  String watchedProgress(Object episode, Object progress) {
    return 'Episode $episode $progress';
  }

  @override
  String get popularAnimeTitle => 'Popular Anime';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get noMoreContent => 'No more content';

  @override
  String get reload => 'Reload';

  @override
  String get todayBroadcast => 'Today\'s Broadcasts';

  @override
  String calendarSummary(Object weekday, Object releases, Object viewers) {
    return '$releases releases on $weekday, $viewers viewers';
  }

  @override
  String get noUpdatesToday => 'No anime updates today';

  @override
  String get forumUnderConstruction => 'Under construction...';

  @override
  String get rankingTitle => 'Ranking';

  @override
  String get allYears => 'All years';

  @override
  String get allMonths => 'All months';

  @override
  String get all => 'All';

  @override
  String yearSuffix(Object year) {
    return '$year';
  }

  @override
  String monthSuffix(Object month) {
    return 'Month $month';
  }

  @override
  String get sortRank => 'Rank';

  @override
  String get sortTrends => 'Trending';

  @override
  String get sortCollects => 'Collections';

  @override
  String get sortDate => 'Date';

  @override
  String get sortTitle => 'Title';

  @override
  String get rankingNoData => 'No data';

  @override
  String get rankingEnd => 'End of list';

  @override
  String rankingLoadFailed(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get detailsTitle => 'Details';

  @override
  String get charactersTitle => 'Characters';

  @override
  String get viewDetails => 'View details';

  @override
  String get producersTitle => 'Producers';

  @override
  String get relatedTitle => 'Related entries';

  @override
  String get commentsTitle => 'Comments';

  @override
  String episodeCount(Object count) {
    return '$count episodes';
  }

  @override
  String yourRating(Object rating) {
    return 'Your rating: $rating';
  }

  @override
  String ratingCount(Object count) {
    return '($count) ratings';
  }

  @override
  String collectionCount(Object count) {
    return '$count collected/';
  }

  @override
  String watchingCount(Object count) {
    return '$count watching/';
  }

  @override
  String droppedCount(Object count) {
    return '$count dropped';
  }

  @override
  String get playIntroTab => 'Introduction';

  @override
  String get playCommentsTab => 'Comments';

  @override
  String get pleaseLogin => 'Please log in';

  @override
  String get loginBeforeDanmaku => 'Please log in before sending danmaku';

  @override
  String get tip => 'Tip';

  @override
  String get danmakuSent => 'Danmaku sent successfully';

  @override
  String get danmakuUnsupported => 'Sending danmaku is not supported';

  @override
  String get episodeSelection => 'Episodes';

  @override
  String get switchToList => 'Switch to list';

  @override
  String get switchToGrid => 'Switch to grid';

  @override
  String get fetchingEpisodes => 'Loading episodes...';

  @override
  String get episodeLoadFailed => 'Failed to load episodes';

  @override
  String get noEpisodeData => 'No episode data';

  @override
  String get updatedProgress => 'Watch progress updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String commentCount(Object count) {
    return 'Comments $count';
  }

  @override
  String get commentLoadFailed => 'Failed to load comments';

  @override
  String get defaultSort => 'Default';

  @override
  String get newestSort => 'Newest';

  @override
  String get noComments => 'No comments';

  @override
  String get commentsAction => 'Comments';

  @override
  String get danmakuSource => 'Danmaku sources:';

  @override
  String totalDanmaku(Object count) {
    return '$count danmaku loaded';
  }

  @override
  String get switchDanmaku => 'Switch danmaku';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get searchResults => 'Search results:';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get noDanmakuEpisodes => 'No danmaku episodes';

  @override
  String get close => 'Close';

  @override
  String get videoSource => 'Video source';

  @override
  String get autoSelectingResource => 'Selecting resource automatically';

  @override
  String get switchSource => 'Switch source';

  @override
  String get sourceActions => 'Source actions';

  @override
  String get openPlaybackPage => 'Open playback page in browser';

  @override
  String get copySourceLink => 'Copy source link';

  @override
  String get copied => 'Copied';

  @override
  String get sourceLinkCopied => 'Source link copied';

  @override
  String lineLabel(Object line) {
    return 'Line: $line';
  }

  @override
  String get recommendationsTitle => 'Recommended';

  @override
  String get recommendationLoadFailed => 'Failed to load recommendations';

  @override
  String get videoSettingsTitle => 'Video settings';

  @override
  String get scheduledOff => 'Scheduled stop';

  @override
  String minutesUnit(Object count) {
    return '$count min';
  }

  @override
  String hoursUnit(Object count) {
    return '$count hr';
  }

  @override
  String hoursMinutesUnit(Object hours, Object minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get moreSettingsBuilding => 'More settings are under construction...';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get back => 'Back';

  @override
  String skipSeconds(Object seconds) {
    return 'Skip $seconds seconds';
  }

  @override
  String get settings => 'Settings';

  @override
  String get turnOffDanmaku => 'Turn off danmaku';

  @override
  String get turnOnDanmaku => 'Turn on danmaku';

  @override
  String get danmakuSettings => 'Danmaku settings';

  @override
  String get loginToSendDanmaku => 'Log in to send danmaku';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get nextEpisode => 'Next episode';

  @override
  String get playbackRate => 'Speed';

  @override
  String get sendDanmakuHint => 'Send danmaku...';

  @override
  String waitToSendDanmaku(Object seconds) {
    return 'Please wait $seconds seconds before sending…';
  }

  @override
  String get collectionPlanToWatch => 'Plan to watch';

  @override
  String get collectionWatched => 'Watched';

  @override
  String get collectionWatching => 'Watching';

  @override
  String get collectionOnHold => 'On hold';

  @override
  String get collectionAbandoned => 'Abandoned';

  @override
  String get collectionLabel => 'Collection';

  @override
  String get searchCollection => 'Search collection';

  @override
  String get collectionKeywordHint => 'Enter collection keywords';

  @override
  String get search => 'Search';

  @override
  String get refreshFailedRetry => 'Refresh failed, please try again later';

  @override
  String get noData => 'No data';

  @override
  String get noMore => 'No more';

  @override
  String get loginToCollect => 'Log in to collect';

  @override
  String get collectionLoadFailed => 'Failed to load, please try again later';

  @override
  String get collectionLoadMoreFailed =>
      'Failed to load more, please try again later';

  @override
  String get moreMenu => 'More menu';

  @override
  String get profileLoadFailed => 'Failed to load user profile';

  @override
  String get profileExpired => 'User profile is no longer valid';

  @override
  String get noUserProfile => 'No user profile';

  @override
  String get confirmLogout => 'Confirm logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get logout => 'Log out';

  @override
  String get playbackHistory => 'Playback history';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get refreshCurrentTab => 'Refresh current tab';

  @override
  String get showUserInfo => 'Show user info';

  @override
  String get hideUserInfo => 'Hide user info';

  @override
  String joinedDate(Object date) {
    return 'Joined $date';
  }

  @override
  String get userInfoSettings => 'User info';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get appAppearance => 'App and appearance';

  @override
  String get themeStyle => 'Theme';

  @override
  String get playbackHistoryVideoSource => 'Playback history and video sources';

  @override
  String get sourceManagement => 'Source management';

  @override
  String get playerSettings => 'Player settings';

  @override
  String get playbackSettings => 'Playback';

  @override
  String get otherSettings => 'Other';

  @override
  String get about => 'About';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSubtitle => 'Easy on the eyes';

  @override
  String get lightMode => 'Light mode';

  @override
  String get lightModeSubtitle => 'Bright and clean';

  @override
  String get followSystem => 'Follow system';

  @override
  String get autoAdapt => 'Adapt automatically';

  @override
  String get themeColor => 'Theme color';

  @override
  String get fontStyle => 'Font style';

  @override
  String get customAppFont => 'Customize app font';

  @override
  String get autoNextEpisode => 'Auto-play next episode';

  @override
  String get autoNextEpisodeSubtitle =>
      'Automatically switch to the next episode when playback finishes';

  @override
  String get adBlocker => 'Ad blocking';

  @override
  String get adBlockerSubtitle => 'Filter inserted ad clips in videos';

  @override
  String get skipDuration => 'Skip duration (seconds)';

  @override
  String get skipDurationSubtitle => 'Used to skip video OP/ED';

  @override
  String get seconds => 'sec';

  @override
  String get playbackProgress => 'Playback progress';

  @override
  String get saveEpisodeProgress => 'Save episode progress';

  @override
  String get saveEpisodeProgressSubtitle =>
      'Save progress automatically at 90%, then start the next unwatched episode';

  @override
  String get playbackControl => 'Playback controls';

  @override
  String get longPressFastForwardSpeed => 'Long-press fast-forward speed';

  @override
  String get danmakuDisplayType => 'Danmaku display type';

  @override
  String get scrollingDanmaku => 'Scrolling danmaku';

  @override
  String get topDanmaku => 'Top danmaku';

  @override
  String get bottomDanmaku => 'Bottom danmaku';

  @override
  String get danmakuSourcePlatform => 'Danmaku source platforms';

  @override
  String get danmakuStyle => 'Danmaku style';

  @override
  String get showBorder => 'Show border';

  @override
  String get showColor => 'Show color';

  @override
  String get massiveMode => 'Dense mode';

  @override
  String get danmakuSpeedTitle => 'Danmaku speed';

  @override
  String danmakuSpeed(Object percent) {
    return 'Speed: $percent%';
  }

  @override
  String get opacity => 'Opacity';

  @override
  String get fontSize => 'Font size';

  @override
  String get displayArea => 'Display area';

  @override
  String get logoutSuccess => 'Logged out';

  @override
  String get openAuthorizationFailed => 'Failed to open authorization page';

  @override
  String get loginStateLoadFailed => 'Failed to load login status';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get loginToManageAccount =>
      'Log in to manage your account and bind a Bangumi account';

  @override
  String get login => 'Log in';

  @override
  String get authorizeLogin => 'Authorize login';

  @override
  String get registerAccount => 'Register';

  @override
  String get accountInfo => 'Account information';

  @override
  String get thirdPartyAccounts => 'Third-party accounts';

  @override
  String get accountActions => 'Account actions';

  @override
  String get nicknameUpdated => 'Nickname updated';

  @override
  String get waitingBangumiAuthorization =>
      'Waiting for Bangumi authorization result...';

  @override
  String get authorizing => 'Authorizing...';

  @override
  String get bound => 'Bound';

  @override
  String get unbound => 'Not bound';

  @override
  String get loading => 'Loading...';

  @override
  String get bindStatusLoadFailed => 'Failed to get binding status';

  @override
  String get bindBangumiHint =>
      'Bind a Bangumi account to sync collections and more';

  @override
  String get bindBangumiAccount => 'Bind Bangumi account';

  @override
  String get confirmUnbind => 'Confirm unbinding';

  @override
  String get unbindConfirmation =>
      'Are you sure you want to unbind your Bangumi account? Some features may be affected.';

  @override
  String get confirmUnbindAction => 'Unbind';

  @override
  String get unbind => 'Unbind';

  @override
  String get bangumiBindSuccessHint =>
      'Bangumi authorization and binding should work normally.';

  @override
  String get bangumiBindFailureHint =>
      'If Bangumi authorization or binding fails, try enabling a VPN or proxy.';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get autoUpdate => 'Automatic updates';

  @override
  String get checkUpdate => 'Check for updates';

  @override
  String get openSource => 'Open source';

  @override
  String get unableOpenWeb => 'Unable to open webpage';

  @override
  String get deviceUnsupportedWeb => 'Your device may not support this feature';

  @override
  String get thanks => 'Acknowledgements';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get specialThanks => 'Special thanks';

  @override
  String get thanksDescription =>
      'Thanks to the excellent open-source projects and technical support that make AnimeFlow better';

  @override
  String get kazumiWebViewSupport =>
      'WebView support provided by the Kazumi project';

  @override
  String get mediaKitDescription =>
      'Cross-platform video player with high-quality playback';

  @override
  String get canvasDanmakuDescription =>
      'Danmaku plugin providing smooth danmaku rendering';

  @override
  String get dandanplayDescription => 'Provides rich danmaku sources';

  @override
  String get bangumiDescription =>
      'Provides anime information and user data synchronization';

  @override
  String get anime4kDescription =>
      'Super-resolution technology for improved video quality';

  @override
  String get traceMoeDescription => 'Provides anime recognition from images';
}
