import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox(Constants.crawlConfigs);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final themeController = Get.put(ThemeController());

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    themeController.initTheme();
    final designSize = Utils.getDesignSize(context);
    return ScreenUtilInit(
      designSize: designSize,
      builder: (context, child) {
        return GetBuilder<ThemeController>(
          builder: (controller) {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeController.lightTheme,
              darkTheme: ThemeController.darkTheme,
              themeMode:
                  controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              initialRoute: RouteName.main,
              routes: getRootRoutes(),
            );
          },
        );
      },
    );
  }
}
