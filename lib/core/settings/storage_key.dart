class StorageKey {
  static const String crawlConfigs = 'crawl_configs_key',
      crawlConfigOrder = 'crawl_config_order',
      settingsKey = 'settings_key',
      visitorId = 'visitor_id',
      presenceId = 'presence_id',
      flowEndpointPool = 'flow_endpoint_pool_v1',
      playPositionKey = 'play_position_key',
      playHistoryKey = 'play_history_key',
      downloadsKey = 'downloads_key',
      searchHistoryKey = 'search_history_key',
      animeInfoCacheKey = 'anime_info_cache_v1',
      characterDataCacheKey = 'character_data_cache_v1',
      subjectMetadataCacheKey = 'subject_metadata_cache_v1',
      subjectCommentsCacheKey = 'subject_comments_cache_v1',
      subjectEpisodesCacheKey = 'subject_episodes_cache_v1',
      popularAnimeCacheKey = 'popular_anime_cache_v1',
      calendarCacheKey = 'calendar_cache_v1',
      userDataCacheKey = 'user_data_cache_v1',
      currentUserProfileKey = 'current_user_profile_v1',
      autoUpdateKey = 'auto_update_key';
}

class DanmakuKey {
  static const String danmakuOn = 'danmaku_on',
      danmakuFontSize = 'danmaku_font_size',
      danmakuArea = 'danmaku_area',
      danmakuOpacity = 'danmaku_opacity',
      danmakuHideScroll = 'danmaku_hide_scroll',
      danmakuHideTop = 'danmaku_hide_top',
      danmakuHideBottom = 'danmaku_hide_bottom',
      danmakuDuration = 'danmaku_duration',
      danmakuMassiveMode = 'danmaku_massive_mode',
      danmakuBorder = 'danmaku_border',
      danmakuColor = 'danmaku_color',
      danmakuLineHeight = 'danmaku_line_height',
      danmakuFontWeight = 'danmaku_font_weight',
      danmakuFontFamily = 'danmaku_font_family',
      danmakuUseFont = 'danmaku_use_font',
      danmakuPlatformBilibili = 'danmaku_platform_bilibili',
      danmakuPlatformGamer = 'danmaku_platform_gamer',
      danmakuPlatformDanDanPlay = 'danmaku_platform_dandanplay',
      danmakuChineseMode = 'danmaku_chinese_mode';
}

class PlaybackKey {
  static const String autoPlayNext = 'playback_auto_play_next',
      episodesProgress = 'playback_episodes_progress',
      fastForwardSpeed = 'playback_fast_forward_speed',
      adBlocker = 'playback_ad_blocker',
      skipDuration = 'playback_skip_duration',
      hardwareDecoder = 'playback_hardware_decoder',
      preferredPlayerKernel = 'playback_preferred_player_kernel',
      showMiniProgressBar = 'playback_show_mini_progress_bar';
}

class PlayerShortcutKey {
  static const String playPause = 'player_shortcut_play_pause',
      seekBackward = 'player_shortcut_seek_backward',
      seekForward = 'player_shortcut_seek_forward',
      seekBackwardSeconds = 'player_shortcut_seek_backward_seconds',
      seekForwardSeconds = 'player_shortcut_seek_forward_seconds',
      volumeUp = 'player_shortcut_volume_up',
      volumeDown = 'player_shortcut_volume_down',
      speedUp = 'player_shortcut_speed_up',
      speedDown = 'player_shortcut_speed_down',
      resetSpeed = 'player_shortcut_reset_speed',
      speedStep = 'player_shortcut_speed_step',
      enterFullscreen = 'player_shortcut_enter_fullscreen',
      exitFullscreen = 'player_shortcut_exit_fullscreen',
      screenshot = 'player_shortcut_screenshot',
      toggleDanmaku = 'player_shortcut_toggle_danmaku',
      nextEpisode = 'player_shortcut_next_episode',
      longPressFastForward = 'player_shortcut_long_press_fast_forward';
}

class DownloadKey {
  static const String downloadDanmaku = 'download_danmaku';
  static const String downloadDirectory = 'download_directory';
  static const String maxParallelEpisodes = 'download_max_parallel_episodes';
  static const String maxParallelSegments = 'download_max_parallel_segments';
}

class SettingKey {
  static const String isMirror = 'setting_is_mirror',
      echImageLoading = 'ech_image_loading',
      echImageRoutes = 'ech_image_routes',
      echImageHost = 'ech_image_host',
      echImageFixedIp = 'ech_image_fixed_ip',
      themeMode = 'theme_mode',
      seedColor = 'theme_seed_color',
      locale = 'app_locale',
      startupPage = 'app_startup_page',
      glassNavigationStyle = 'glass_navigation_bar',
      defaultCollectionType = 'default_collection_type',
      rankingDetailsLayout = 'ranking_details_layout',
      collectionSort = 'collection_sort',
      calendarTagFilter = 'calendar_tag_filter',
      fontFamily = 'font_family',
      selectedFontId = 'selected_font_id',
      downloadedFonts = 'downloaded_fonts',
      downloadedFontsMeta = 'downloaded_fonts_meta',
      fontRepoUseCdn = 'font_repo_use_cdn';
}
