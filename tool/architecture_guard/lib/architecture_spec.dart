import 'src/model.dart';

/// 只维护业务/UI 分类和生成代码循环分组，不要求登记 feature 或业务入口。
ArchitectureSpec projectArchitecture() => ArchitectureSpec(
  scopes: [
    // 这些 Provider 管理展示状态，允许引用 UI。
    for (final path in [
      'lib/features/play/presentation/providers/video_ui_provider.dart',
      'lib/features/play/presentation/providers/captcha_provider.dart',
      'lib/features/settings/presentation/providers/setting_provider.dart',
    ])
      SourceScope(path, Responsibility.ui),
    // 播放器绑定负责装配实现，不属于业务流程。
    SourceScope(
      'lib/features/play/application/player_bindings.dart',
      Responsibility.other,
    ),
    SourceScope('lib/**/application/**.dart', Responsibility.business),
    SourceScope('lib/**/domain/**.dart', Responsibility.business),
    SourceScope(
      'lib/features/*/presentation/providers/**.dart',
      Responsibility.business,
    ),
    for (final directory in ['pages', 'widgets', 'extensions', 'utils'])
      SourceScope(
        'lib/features/*/presentation/$directory/**.dart',
        Responsibility.ui,
      ),
    SourceScope('lib/shared/widgets/**.dart', Responsibility.ui),
    SourceScope('lib/shared/navigation/app_navigator.dart', Responsibility.ui),
    SourceScope(
      'lib/shared/navigation/app_route_observer.dart',
      Responsibility.ui,
    ),
    SourceScope(
      'lib/shared/navigation/app_navigator_provider.dart',
      Responsibility.ui,
    ),
  ],
  forbiddenDependencies: {
    'lib/features/**.dart': {'lib/app/router/**.dart'},
    'lib/shared/**.dart': {'lib/app/router/**.dart'},
    'lib/shared/navigation/**.dart': {
      'lib/app/**.dart',
      'lib/features/**.dart',
    },
  },
  uiLibraries: {
    'dart:ui',
    'dart:ui_web',
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    'package:flutter/cupertino.dart',
    'package:flutter/rendering.dart',
    'package:flutter/painting.dart',
    'package:flutter/src/widgets/**',
    'package:flutter/src/material/**',
    'package:flutter/src/cupertino/**',
    'package:flutter/src/rendering/**',
    'package:flutter/src/painting/**',
    'package:material_ui/**',
    'package:cupertino_ui/**',
  },
  generatedGroups: {
    // 只折叠生成器固定产生的国际化内部循环，仍检查其对外依赖。
    'flutter_localizations': {
      'lib/app/localization/app_localizations.dart',
      'lib/app/localization/app_localizations_en.dart',
      'lib/app/localization/app_localizations_zh.dart',
    },
    // ANTLR 固定生成的解析器与监听器相互引用；只折叠这两个文件，仍检查对外依赖。
    'bbcode_antlr': {
      'lib/shared/widgets/bbcode/generated/BBCodeParser.dart',
      'lib/shared/widgets/bbcode/generated/BBCodeListener.dart',
    },
  },
);
