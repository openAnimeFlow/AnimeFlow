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

/// 导航实现由所在的 ProviderScope 提供，测试环境也遵循此规则。
AppNavigator appNavigatorOf(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false)
        .read(_navigatorProvider);
