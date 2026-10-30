import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter/widgets.dart';

import 'app_navigator.dart';

final _navigatorProvider = Provider<AppNavigator>((ref) {
  throw StateError('AppNavigator must be supplied by the application');
});

/// 供应用组装入口和测试注入导航实现。
Override overrideAppNavigator(AppNavigator navigator) =>
    _navigatorProvider.overrideWithValue(navigator);

/// UI 层统一导航入口，例如 `appNavigatorOf(context).openSearch<void>()`。
///
/// context 仅用于读取所在 ProviderScope 中的实现，不会被导航器持有。
/// 应用入口和测试需注入与 MaterialApp.router 相同的路由器。
AppNavigator appNavigatorOf(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false).read(_navigatorProvider);
