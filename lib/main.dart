import 'dart:io';
import 'package:anime_flow/repository/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/controllers/theme_controller.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Storage.init();
  final themeController = Get.put(ThemeController());
  await themeController.initTheme();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeController get themeController => Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) {
        return GetMaterialApp(
          // debugShowCheckedModeBanner: false,
          theme: controller.lightTheme,
          darkTheme: controller.darkTheme,
          themeMode: controller.themeMode,
          initialRoute: RouteName.main,
          routes: getRootRoutes(),
          // builder: (context, child) {
          //   if (Utils.isDesktop) {
          //     return WindowsTitleBar(
          //       child: child,
          //     );
          //   } else {
          //     return child ?? const SizedBox.shrink();
          //   }
          // },
        );
      },
    );
  }
}
