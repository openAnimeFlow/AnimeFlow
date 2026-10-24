import 'package:anime_flow/app/router/go_app_navigator.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';

final navigationOverrides = [
  appNavigatorProvider.overrideWithValue(const GoAppNavigator()),
];
