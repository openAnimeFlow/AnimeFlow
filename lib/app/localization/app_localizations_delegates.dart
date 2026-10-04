import 'package:flutter/widgets.dart' show LocalizationsDelegate;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'app_localizations.dart';

/// 应用实际注册的本地化代理。
final List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
