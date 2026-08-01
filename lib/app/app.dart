import 'dart:io';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/locale_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/theme/theme_provider.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/shared/widgets/windows_title_bar.dart';
import 'package:anime_flow/app/app_version.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final themeState = ref.watch(themeProvider);
        final locale = ref.watch(localeProvider);
        final fontFamily = themeState.fontFamily;
        return MaterialApp.router(
          key: ValueKey(fontFamily),
          routeInformationProvider: appRouter.routeInformationProvider,
          routeInformationParser: appRouter.routeInformationParser,
          routerDelegate: appRouter.routerDelegate,
          backButtonDispatcher: appRouter.backButtonDispatcher,
          theme: buildLightTheme(themeState.seedColor, fontFamily: fontFamily),
          darkTheme:
              buildDarkTheme(themeState.seedColor, fontFamily: fontFamily),
          themeMode: themeState.themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
