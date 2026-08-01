import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
      <String>['zh'].contains(locale.languageCode);

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
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
