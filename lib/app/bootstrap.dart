import 'dart:async';
import 'dart:io';

import 'package:anime_flow/app/app.dart';
import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/features/download/application/download_foreground_service.dart';
import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/image/ech_http_licenses.dart';
import 'package:anime_flow/core/network/image/image_cache_manager.dart';
import 'package:anime_flow/core/presence/presence_service.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/source/data/services/source_config_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerEchHttpLicenses();
  initializeErrorLogging();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Storage.init();
  CachedNetworkImageProvider.defaultCacheManager =
      AnimeImageCacheManager.instance;
  await DownloadForegroundService.initialize();
  await SelectedFont.initOnStartup();
  appPackageInfo = await PackageInfo.fromPlatform();
  await DioFactory.initialize();
  unawaited(
    PresenceService.instance.start(appVersion: appPackageInfo!.version),
  );

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
  container.read(appInfoProvider);
  unawaited(container.read(shadersDirectoryProvider.future));
  unawaited(SourceConfigInitializer().initialize());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
