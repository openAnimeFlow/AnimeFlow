import 'src/model.dart';

// The only architecture policy. New features/roles must be deliberately registered.
// Direct API access is a supported design, not legacy debt.
ArchitectureSpec projectArchitecture() {
  final features = <String, List<String>>{
    'anime_info': ['data', 'presentation'],
    'anime_preview': ['presentation'],
    'app_update': ['application', 'presentation'],
    'auth': ['application', 'presentation'],
    'calendar': ['presentation'],
    'character_info': ['presentation'],
    'characters': ['data', 'presentation'],
    'download': ['application', 'data', 'presentation'],
    'home': ['data', 'presentation'],
    'play': ['application', 'data', 'domain', 'infrastructure', 'presentation'],
    'ranking': ['presentation'],
    'search': ['data', 'presentation'],
    'settings': ['presentation'],
    'shaders': [],
    'shell': ['presentation'],
    'source': ['application', 'data'],
    'user': ['application', 'data', 'presentation'],
    'user_space': ['presentation'],
  };
  // Existing directions are recorded explicitly. Internal cross-feature edges
  // are separately frozen by R06 until each API entry has been introduced.
  const dependencies = <String, Set<String>>{
    'anime_info': {'auth', 'characters', 'play', 'user'},
    'character_info': {'characters'},
    'download': {'play'},
    'home': {'calendar', 'play'},
    'play': {
      'anime_info',
      'auth',
      'download',
      'settings',
      'shaders',
      'source',
      'user',
    },
    'settings': {'app_update', 'auth', 'download', 'play', 'source', 'user'},
    'shell': {'auth', 'user'},
    'user': {'auth'},
  };
  const uiProviders = {
    'play': {'video_ui_provider.dart', 'captcha_provider.dart'},
    'settings': {'setting_provider.dart'},
  };
  // Classification is per use case, not per feature. Simple play/history,
  // comments, recommendation and online-count Providers keep direct API access.
  const repositoryProviders = {
    'play': {
      'play_provider.dart',
      'subject_episodes_provider.dart',
      'video_source_provider.dart',
      'episodes_provider.dart',
    },
    'download': {'download_provider.dart'},
  };
  // App-only page and startup bindings; these grant no cross-feature access.
  const compositionEntries = <String, Set<String>>{
    'anime_info': {
      'lib/features/anime_info/presentation/pages/anime_info_page.dart',
      'lib/features/anime_info/presentation/providers/anime_info_provider.dart',
    },
    'anime_preview': {
      'lib/features/anime_preview/presentation/pages/anime_preview.dart',
    },
    'app_update': {
      'lib/features/app_update/application/app_info_provider.dart',
      'lib/features/app_update/application/app_info_state.dart',
      'lib/features/app_update/presentation/widgets/version_update_ui.dart',
    },
    'auth': {
      'lib/features/auth/presentation/widgets/oauth_notice_listener.dart',
      'lib/features/auth/presentation/pages/forgot_password_page.dart',
      'lib/features/auth/presentation/pages/login_page.dart',
      'lib/features/auth/presentation/pages/oauth_callback_page.dart',
      'lib/features/auth/presentation/pages/register_page.dart',
    },
    'calendar': {'lib/features/calendar/presentation/pages/calendar_page.dart'},
    'character_info': {
      'lib/features/character_info/presentation/pages/character_info_page.dart',
    },
    'characters': {
      'lib/features/characters/presentation/pages/characters_page.dart',
    },
    'download': {
      'lib/features/download/application/download_directory/restore_download_directory_access.dart',
      'lib/features/download/application/download_foreground_service.dart',
      'lib/features/download/application/download_path_migration.dart',
      'lib/features/download/presentation/pages/download_page.dart',
    },
    'home': {'lib/features/home/presentation/pages/home_page.dart'},
    'play': {
      'lib/features/play/presentation/pages/play_page.dart',
      'lib/features/play/presentation/pages/play_record_page.dart',
    },
    'ranking': {'lib/features/ranking/presentation/pages/ranking_page.dart'},
    'search': {
      'lib/features/search/presentation/pages/image_search_page.dart',
      'lib/features/search/presentation/pages/search_page.dart',
    },
    'settings': {
      'lib/features/settings/presentation/pages/about/about_page.dart',
      'lib/features/settings/presentation/pages/about/author_page.dart',
      'lib/features/settings/presentation/pages/about/sponsor_page.dart',
      'lib/features/settings/presentation/pages/about/thanks_page.dart',
      'lib/features/settings/presentation/pages/about/updates_page.dart',
      'lib/features/settings/presentation/pages/about/website_page.dart',
      'lib/features/settings/presentation/pages/account_settings_page.dart',
      'lib/features/settings/presentation/pages/agreement_page.dart',
      'lib/features/settings/presentation/pages/danmaku_setting_page.dart',
      'lib/features/settings/presentation/pages/download_settings.dart',
      'lib/features/settings/presentation/pages/error_logs_page.dart',
      'lib/features/settings/presentation/pages/font_page.dart',
      'lib/features/settings/presentation/pages/general_settings.dart',
      'lib/features/settings/presentation/pages/playback_settings.dart',
      'lib/features/settings/presentation/pages/player_shortcuts_page.dart',
      'lib/features/settings/presentation/pages/plugins/add_plugins.dart',
      'lib/features/settings/presentation/pages/plugins/download_plugins.dart',
      'lib/features/settings/presentation/pages/plugins/plugins.dart',
      'lib/features/settings/presentation/pages/settings_page.dart',
      'lib/features/settings/presentation/pages/theme.dart',
      'lib/features/settings/presentation/providers/font_provider.dart',
    },
    'shaders': {'lib/features/shaders/shaders_controller.dart'},
    'shell': {'lib/features/shell/presentation/pages/app_shell_page.dart'},
    'source': {
      'lib/features/source/data/services/source_config_initializer.dart',
    },
    'user': {
      'lib/features/user/presentation/widgets/collection_sync_lifecycle.dart',
      'lib/features/user/presentation/pages/user_page.dart',
    },
    'user_space': {
      'lib/features/user_space/presentation/pages/user_space_page.dart',
    },
  };
  final modules = <ModuleSpec>[
    ModuleSpec('hive_registration', 'lib/hive_registrar.g.dart', [
      SourceScope('lib/hive_registrar.g.dart', Responsibility.composition),
    ]),
    ModuleSpec('entry', 'lib/main.dart', [
      SourceScope('lib/main.dart', Responsibility.composition),
    ]),
    ModuleSpec('app', 'lib/app', [
      SourceScope('lib/app/**.dart', Responsibility.composition),
    ]),
    ModuleSpec('core', 'lib/core', [
      SourceScope('lib/core/**.dart', Responsibility.foundation),
    ]),
    ModuleSpec('shared_models', 'lib/shared/models', [
      SourceScope('lib/shared/models/**.dart', Responsibility.model),
    ]),
    ModuleSpec('shared_widgets', 'lib/shared/widgets', [
      SourceScope('lib/shared/widgets/**.dart', Responsibility.ui),
    ]),
  ];
  for (final entry in features.entries) {
    final name = entry.key;
    final root = 'lib/features/$name';
    final scopes = <SourceScope>[];
    final apiEntries = switch (name) {
      'auth' => {'$root/auth_api.dart'},
      'user' => {'$root/user_api.dart', '$root/user_events.dart'},
      _ => <String>{},
    };
    for (final entry in apiEntries) {
      scopes.add(SourceScope(entry, Responsibility.business));
    }
    for (final layer in entry.value) {
      if (layer == 'presentation') {
        // Non-overlapping globs make unclassified files fail rather than silently
        // treating unknown presentation subdirectories as business or UI.
        for (final directory in ['pages', 'widgets', 'extensions', 'utils']) {
          scopes.add(
            SourceScope(
              '$root/presentation/$directory/**.dart',
              Responsibility.ui,
              required: false,
            ),
          );
        }
        final uiNames = uiProviders[name] ?? <String>{};
        for (final file in uiNames) {
          scopes.add(
            SourceScope(
              '$root/presentation/providers/$file',
              Responsibility.ui,
            ),
          );
        }
        // Glob does not support exclusions: business/UI providers are separated
        // by a dedicated scope implementation below.
        for (final mode in AccessMode.values) {
          scopes.add(
            ProviderScope(
              '$root/presentation/providers/**.dart',
              uiNames,
              repositoryProviders[name] ?? {},
              mode: mode,
            ),
          );
        }
      } else {
        scopes.add(
          SourceScope('$root/$layer/**.dart', switch (layer) {
            'domain' => Responsibility.domain,
            'data' => Responsibility.data,
            'infrastructure' => Responsibility.adapter,
            _ => Responsibility.business,
          }, mode: layer == 'application' ? AccessMode.repository : null),
        );
      }
    }
    if (name == 'shaders') {
      scopes.add(
        SourceScope('$root/shaders_controller.dart', Responsibility.adapter),
      );
    }
    modules.add(
      ModuleSpec(
        name,
        root,
        scopes,
        dependencies: dependencies[name] ?? {},
        apiEntries: apiEntries,
        uiEntries: name == 'auth'
            ? {
                'lib/features/auth/presentation/pages/login_page.dart',
                'lib/features/auth/presentation/widgets/graphic_captcha.dart',
                'lib/features/auth/presentation/widgets/send_code_button.dart',
              }
            : {},
        pageEntries: compositionEntries[name] ?? {},
      ),
    );
  }
  return ArchitectureSpec(
    modules,
    strictScopes: {
      for (final rule in ['R03', 'R06', 'R09'])
        rule: {'lib/features/auth/**.dart', 'lib/features/user/**.dart'},
      // Routing/UI cycles are separate legacy work; business cycles are closed.
      'R07': {
        'lib/features/auth/application/**.dart',
        'lib/features/user/application/**.dart',
      },
    },
    domainCoreTypes: {'lib/core/constants/storage_key.dart'},
    dataContracts: {
      'lib/features/user/user_events.dart': '公开的收藏修订通知契约，仅导出缓存失效信号。',
      'lib/features/user/application/collection_revision_provider.dart':
          '仅发布收藏修订信号，供缓存失效使用；不包含会话或同步业务编排。',
    },
    generatedGroups: {
      'flutter_localizations': {
        'lib/app/localization/app_localizations.dart',
        'lib/app/localization/app_localizations_en.dart',
        'lib/app/localization/app_localizations_zh.dart',
      },
    },
  );
}

class ProviderScope extends SourceScope {
  ProviderScope(
    String pattern,
    this.uiFiles,
    this.repositoryFiles, {
    required AccessMode mode,
  }) : super(pattern, Responsibility.business, mode: mode, required: false);
  final Set<String> uiFiles;
  final Set<String> repositoryFiles;
  @override
  bool matches(String path) =>
      super.matches(path) &&
      !uiFiles.contains(path.split('/').last) &&
      (repositoryFiles.contains(path.split('/').last) ==
          (mode == AccessMode.repository));
}
