import 'dart:io';
import 'package:anime_flow/pages/settings/pages/font/font_provider.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await Storage.init();
  await SelectedFont.initOnStartup();

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

  final container = ProviderContainer();
  container.read(myControllerProvider);

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
          builder: BotToastInit(),
          routeInformationProvider: appRouter.routeInformationProvider,
          routeInformationParser: appRouter.routeInformationParser,
          routerDelegate: appRouter.routerDelegate,
          backButtonDispatcher: appRouter.backButtonDispatcher,
          theme: buildLightTheme(themeState.seedColor, fontFamily: fontFamily),
          darkTheme: buildDarkTheme(themeState.seedColor, fontFamily: fontFamily),
          themeMode: themeState.themeMode,
        );
      },
    );
  }
}
