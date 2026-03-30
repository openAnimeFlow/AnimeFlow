import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用根 [ProviderContainer]，供 `runApp` 与尚未持有 [WidgetRef] 的代码
final globalProviderContainer = ProviderContainer();
