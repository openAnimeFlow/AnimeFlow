import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 应用根 [ProviderContainer]，供无 [WidgetRef] 的模块读取全局 Provider
ProviderContainer? appProviderContainer;

/// 启动阶段预加载的应用信息，供同步读取版本号等场景复用
PackageInfo? appPackageInfo;
