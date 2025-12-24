import 'package:anime_flow/pages/Main/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/anime_info/index.dart';

class RouteName {
  static const String main = "/";
  static const String login = "/login";
  static const String animeInfo = "/anime_info";
  static const String play = "/play";
  static const String search = "/search";
  static const String calendar = "/calendar";
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    RouteName.main: (context) => const MainPage(),
    RouteName.login: (context) => const MyPage(),
    RouteName.animeInfo: (context) => const AnimeDetailPage(),
    RouteName.play: (context) => const PlayPage(),
    RouteName.search: (context) => const SearchPage(),
    RouteName.calendar: (context) => const CalendarPage(),
  };
}
