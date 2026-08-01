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
}
