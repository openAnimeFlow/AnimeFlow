import 'dart:io';
import 'package:anime_flow/constants/constants.dart';
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
  await Hive.openBox(Constants.crawlConfigs);
  final themeController = Get.put(ThemeController());
  await themeController.initTheme();
  
  // Windows 平台初始化窗口管理器
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
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
              debugShowCheckedModeBanner: false,
              theme: controller.lightTheme,
              darkTheme: controller.darkTheme,
              themeMode: controller.themeMode,
              initialRoute: RouteName.main,
              routes: getRootRoutes(),
            );
          },
        );
  }
}
