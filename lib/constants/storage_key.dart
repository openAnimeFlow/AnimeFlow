class StorageKey {
  /// 爬虫配置表
  static const String crawlConfigs = 'crawl_configs_key';

  static const String settingsKey = 'settings_key';

  static const String playPositionKey = 'play_position_key';

  static const String playHistoryKey = 'play_history_key';
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
      danmakuUseSystemFont = 'danmaku_use_system_font',
      danmakuPlatformBilibili = 'danmaku_platform_bilibili',
      danmakuPlatformGamer = 'danmaku_platform_gamer',
      danmakuPlatformDanDanPlay = 'danmaku_platform_dandanplay';
}

class PlaybackKey {
  static const String autoPlayNext = 'playback_auto_play_next',
      episodesProgress = 'playback_episodes_progress',
      fastForwardSpeed = 'playback_fast_forward_speed';
}
