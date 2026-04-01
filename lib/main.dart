import 'dart:io';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:anime_flow/providers/global_provider_container.dart';
import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Storage.init();
  await globalProviderContainer.read(themeProvider.notifier).loadFromPrefs();

  // 桌面平台初始化窗口管理器
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
        // titleBarStyle: TitleBarStyle.hidden,
        );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  if (Platform.isAndroid) {
    await Utils.checkWebViewFeatureSupport();
  }
  runApp(UncontrolledProviderScope(
    container: globalProviderContainer,
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return GetMaterialApp.router(
      routeInformationProvider: appRouter.routeInformationProvider,
      routeInformationParser: appRouter.routeInformationParser,
      routerDelegate: appRouter.routerDelegate,
      backButtonDispatcher: appRouter.backButtonDispatcher,
      theme: buildLightTheme(themeState.seedColor),
      darkTheme: buildDarkTheme(themeState.seedColor),
      themeMode: themeState.themeMode,
    );
  }
}
