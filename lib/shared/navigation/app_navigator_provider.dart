import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'app_navigator.dart';

/// 在应用组装入口注入导航实现，测试中可注入替代实现。
final appNavigatorProvider = Provider<AppNavigator>((ref) {
  throw StateError('AppNavigator must be supplied by the application');
});

/// 供无需持有 WidgetRef 的组件在事件回调中获取导航接口。
/// 导航实现由所在的 ProviderScope 提供，测试环境也遵循此规则。
AppNavigator appNavigatorOf(BuildContext context) =>
    ProviderScope.containerOf(context, listen: false)
        .read(appNavigatorProvider);
