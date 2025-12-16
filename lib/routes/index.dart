import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/Login/index.dart';
import 'package:anime_flow/pages/anime_info/index.dart';

import '../pages/Main/index.dart';

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    "/": (context) => const MainPage(),
    "/login": (context) => const LoginPage(),
    "/anime_detail": (context) => const AnimeDetailPage(),
    "/play": (context) => const PlayPage(),
    "/search": (context) => const SearchPage(),
  };
}
