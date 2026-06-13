import 'dart:async';
import 'dart:io';

import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/features/app/app_info_provider.dart';
import 'package:anime_flow/features/app/app_provider_container.dart';
import 'package:anime_flow/features/my/my_controller_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/pages/settings/pages/font/font_provider.dart';
import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/widget/windows_title_bar.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Storage.init();
  await SelectedFont.initOnStartup();
  appPackageInfo = await PackageInfo.fromPlatform();

  // 桌面平台初始化窗口管理器
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
  container.read(myControllerProvider);
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final themeState = ref.watch(themeProvider);
        final fontFamily = themeState.fontFamily;
        return MaterialApp.router(
          key: ValueKey(fontFamily),
          routeInformationProvider: appRouter.routeInformationProvider,
          routeInformationParser: appRouter.routeInformationParser,
          routerDelegate: appRouter.routerDelegate,
          backButtonDispatcher: appRouter.backButtonDispatcher,
          theme: buildLightTheme(themeState.seedColor, fontFamily: fontFamily),
          darkTheme: buildDarkTheme(themeState.seedColor, fontFamily: fontFamily),
          themeMode: themeState.themeMode,
          builder: (context, child) {
            var body = BotToastInit()(context, child);
            body = AppVersionUpdateListener(child: body);
            if (Platform.isWindows) {
              body = WindowsTitleBar(
                title: 'AnimeFlow',
                icon: SizedBox(
                    width: 25,
                    height: 25,
                    child: Image.asset(AssetsPathConstants.logo)),
                child: body,
              );
            }
            return body;
          },
        );
      },
    );
  }
}
