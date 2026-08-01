import 'dart:async';
import 'dart:io';

import 'package:anime_flow/app/app.dart';
import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/features/app_update/application/app_provider_container.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/core/utils/crawl_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Storage.init();
  await SelectedFont.initOnStartup();
  appPackageInfo = await PackageInfo.fromPlatform();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    final windowOptions = WindowOptions(
      titleBarStyle:
          Platform.isWindows ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final container = ProviderContainer();
  appProviderContainer = container;
  container.read(appInfoProvider);
  unawaited(container.read(shadersDirectoryProvider.future));
  unawaited(CrawlConfig.initCrawlConfigs());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
