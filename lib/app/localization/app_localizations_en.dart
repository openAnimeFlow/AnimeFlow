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
  String get fitAuto => 'Contain';

  @override
  String get fitCrop => 'Crop to fill';

  @override
  String get fitStretch => 'Stretch to fill';

  @override
  String get buffering => 'Buffering...';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get disableAutoUpdate => 'Disable automatic updates';

  @override
  String get updateLater => 'Update later';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDownloadHint =>
      'The package is downloaded from GitHub. Network speeds may be slow in some regions; use a proxy for better performance.';

  @override
  String get downloading => 'Downloading...';

  @override
  String get selectDownloadSource => 'Select a download source:';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get latestVersion => 'You are using the latest version';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String updateDownloadFailed(Object error) {
    return 'Update download failed: $error';
  }

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get downloadCancelledMessage => 'The download was cancelled';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get packageDownloaded => 'The package has been downloaded';

  @override
  String get openFailed => 'Failed to open';

  @override
  String openFileManagerFailed(Object error) {
    return 'Unable to open the file manager: $error';
  }

  @override
  String get openPackageFolder => 'Open package folder';

  @override
  String get openSourceLicense => 'Open Source License';

  @override
  String get noLicenseInfo => 'No license information';

  @override
  String get noMoreContent => 'No more content';

  @override
  String get reload => 'Reload';

  @override
  String get todayBroadcast => 'Today\'s Broadcasts';

  @override
  String get back => 'Back';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String releaseCount(Object count) {
    return '$count releases';
  }

  @override
  String noUpdatesOnWeekday(Object weekday) {
    return 'No anime updates on $weekday';
  }

  @override
  String get animeCount => 'Anime count';

  @override
  String get totalWatchers => 'Total viewers';

  @override
  String get averageRating => 'Average rating';

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
  String get characterWorks => 'Works';

  @override
  String get backToTop => 'Back to top';

  @override
  String get noComments => 'No comments';

  @override
  String get characterWorksLoadFailed => 'Failed to load works';

  @override
  String get noCharacterWorks => 'No works';

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
  String get confirmAllWatched => 'Mark all as watched?';

  @override
  String get confirmAllWatchedMessage =>
      'Mark all episodes of this anime as watched?';

  @override
  String get markAllWatchedSuccess => 'All episodes marked as watched';

  @override
  String loadedEpisodes(Object count) {
    return '$count episodes loaded';
  }

  @override
  String get allWatched => 'All watched';

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
  String get imageSearch => 'Image search';

  @override
  String get switchToUploadImage => 'Switch to image upload';

  @override
  String get switchToImageUrl => 'Switch to image URL';

  @override
  String get searching => 'Searching...';

  @override
  String get startSearch => 'Start search';

  @override
  String get tapToSelectImage => 'Tap to select an image';

  @override
  String get supportedImageFormats => 'JPG, PNG, and WEBP supported';

  @override
  String get imagePreviewFailed => 'Image preview failed';

  @override
  String get imageSelected => 'Image selected';

  @override
  String get tapToReselectImage => 'Tap to select another image';

  @override
  String get reselect => 'Select again';

  @override
  String get enterImageUrl => 'Enter an image URL';

  @override
  String get clear => 'Clear';

  @override
  String get enterImageUrlToPreview => 'Enter an image URL to preview';

  @override
  String get imageLoadFailed => 'Failed to load image';

  @override
  String get checkImageUrl => 'Check whether the URL is valid';

  @override
  String get recognizingImage => 'Recognizing image';

  @override
  String get matchingAnimeFromImage =>
      'Please wait while anime information is matched';

  @override
  String get imageSearchResultPlaceholder => 'Search results will appear here';

  @override
  String get noImageSearchResults => 'No search results found';

  @override
  String get startImageSearchHint =>
      'Select an image or enter an image URL to search';

  @override
  String get recognitionResults => 'Recognition results';

  @override
  String get originalAspectRatioTip =>
      'Only screenshots with the original aspect ratio are supported';

  @override
  String get clearScreenshotTip =>
      'Use a clear screenshot without heavy compression or watermarks';

  @override
  String get searchEnginePoweredBy => 'Powered by ';

  @override
  String get providesSupport => '';

  @override
  String get searchAnimeByImage => 'Search anime by image';

  @override
  String get searchSuggestions => 'Search suggestions';

  @override
  String searchResultCount(Object count) {
    return '$count results found';
  }

  @override
  String get enterKeywordToSearch => 'Enter a keyword to search';

  @override
  String get searchHistory => 'Search history';

  @override
  String get clearAll => 'Clear all';

  @override
  String get delete => 'Delete';

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
  String get error => 'Error';

  @override
  String get moreActions => 'More actions';

  @override
  String get unableOpenLink => 'Unable to open link';

  @override
  String get websiteLinkCopied => 'Website link copied to clipboard';

  @override
  String saveImageFailed(Object error) {
    return 'Failed to save image: $error';
  }

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get downloadCover => 'Download cover';

  @override
  String get copyWebsite => 'Copy website link';

  @override
  String get loginSuccess => 'Logged in successfully';

  @override
  String get welcomeTo => 'Welcome to ';

  @override
  String get loginToManageCollection => 'Log in to manage your collection';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get bangumiAuthorizeLogin => 'Authorize with Bangumi';

  @override
  String get bangumi => 'Bangumi';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get authorizeLogin => 'Authorize login';

  @override
  String get registerAccount => 'Register';

  @override
  String get registerSuccess => 'Registered successfully';

  @override
  String get registerTitle => 'Register';

  @override
  String get createAccount => 'Create an account';

  @override
  String get registerSubtitle =>
      'Join AnimeFlow and sync your anime experience';

  @override
  String get enterGraphicCaptcha => 'Please enter the image captcha first';

  @override
  String get emailCodeSent => 'Verification code sent; check your email';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordLengthRange => 'Password must be 6–30 characters';

  @override
  String get enterConfirmPassword => 'Please enter your password again';

  @override
  String get passwordMismatch => 'The passwords do not match';

  @override
  String get emailVerificationCode => 'Email verification code';

  @override
  String get enterEmailCode => 'Please enter the email verification code';

  @override
  String get emailCodeLength => 'The verification code must contain 6 digits';

  @override
  String get haveAccountBackToLogin =>
      'Already have an account? Back to log in';

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

  @override
  String fontRefreshFailed(Object error) {
    return 'Refresh failed: $error';
  }

  @override
  String get fontStylePageTitle => 'Font style';

  @override
  String get refreshFontList => 'Refresh font list';

  @override
  String get fontLibrary => 'Font library';

  @override
  String get cdnAcceleration => 'CDN acceleration';

  @override
  String get fontDelayHint => 'Newly added fonts may take time to appear';

  @override
  String get cdnTooltip =>
      'On: fetch fonts through jsDelivr; off: connect directly to GitHub Raw through a mirror';

  @override
  String get fontRestartHint =>
      'Restart the app if the font effect is not fully displayed';

  @override
  String get noOtherFonts => 'No other fonts available';

  @override
  String get downloadedOrphanFonts => 'Downloaded locally (removed remotely)';

  @override
  String get orphanFontDescription =>
      'These fonts are no longer in the remote repository but remain on your device. You can delete or continue using them here.';

  @override
  String get fontListLoadFailed => 'Failed to load font list';

  @override
  String get systemFont => 'Follow system';

  @override
  String get systemFontSubtitle => 'Use the system default font';

  @override
  String fontAuthorInfo(Object author, Object size) {
    return 'Author: $author - Font size: $size';
  }

  @override
  String get downloadFont => 'Download font';

  @override
  String get appliedFont => 'Applied, tap to stop using';

  @override
  String get applyFont => 'Tap to apply this font';

  @override
  String get deleteDownloadedFont => 'Delete downloaded font';

  @override
  String get downloadFontFailedRetry => 'Download failed, tap to retry';

  @override
  String get deleteFont => 'Delete font';

  @override
  String deleteSelectedFontConfirmation(Object fontName) {
    return 'Delete the local file for “$fontName” and restore the system font?';
  }

  @override
  String deleteFontConfirmation(Object fontName) {
    return 'Delete the local font file for “$fontName”?';
  }

  @override
  String get previewLoadFailed => 'Failed to load preview';

  @override
  String get fontPreviewHeadline => 'Welcome to AnimeFlow';

  @override
  String get orphanFontAvailable =>
      'Removed remotely, but the local font can still be used';

  @override
  String get orphanFontMissing =>
      'The local font file is missing; you can clean up this record here';

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
  String get downloadConfig => 'Download configuration';

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
  String get downloadSuccess => 'Download successful';

  @override
  String pluginDownloaded(Object name) {
    return 'Plugin \"$name\" downloaded';
  }

  @override
  String pluginDownloadFailed(Object error, Object name) {
    return 'Error downloading plugin \"$name\": $error';
  }

  @override
  String get updateSuccess => 'Update successful';

  @override
  String pluginUpdated(Object name, Object version) {
    return 'Plugin \"$name\" updated to version $version';
  }

  @override
  String pluginUpdateFailed(Object error, Object name) {
    return 'Error updating plugin \"$name\": $error';
  }

  @override
  String get downloadSources => 'Download data sources';

  @override
  String get downloadSourcesSubtitle =>
      'Data sources are downloaded from GitHub. Check your network and pull to refresh.';

  @override
  String get useMirror => 'Use mirror';

  @override
  String get useMirrorSubtitle =>
      'Enable this when GitHub cannot be accessed directly to fetch the plugin list through a mirror.';

  @override
  String get noDataRefresh => 'No data found, please refresh';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get updating => 'Updating…';

  @override
  String get update => 'Update';

  @override
  String pluginVersionDate(Object date, Object version) {
    return '版本：$version - $date';
  }

  @override
  String get collectionSyncTitle => 'Collection Sync';

  @override
  String get collectionSyncStarted => 'Collection sync started';

  @override
  String get syncStartFailed => 'Failed to start sync';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get refreshStatusFailed => 'Failed to refresh status';

  @override
  String syncedItems(Object count) {
    return 'Synced $count items';
  }

  @override
  String get syncInProgress => 'Syncing…';

  @override
  String get syncBangumiCollection => 'Sync Bangumi collection';

  @override
  String get syncStatusLoadFailed => 'Failed to load sync status';

  @override
  String get syncStatusIdle => 'Not synced';

  @override
  String get syncStatusRunning => 'Syncing';

  @override
  String get syncStatusSuccess => 'Sync complete';

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get introduction => 'Introduction';

  @override
  String get collection => 'Collection';

  @override
  String get timeline => 'Timeline';

  @override
  String get userInfoUnavailable => 'Unable to load user information';

  @override
  String get timelineComingSoon => 'Timeline is coming soon';

  @override
  String get statistics => 'Statistics';

  @override
  String get bio => 'Bio';

  @override
  String get location => 'Location';

  @override
  String get website => 'Website';

  @override
  String get mysteriousUser => 'This user is mysterious';

  @override
  String watchedLabel(Object progress) {
    return 'Watched $progress';
  }

  @override
  String playEpisode(Object episode) {
    return 'Play ($episode)';
  }
}
