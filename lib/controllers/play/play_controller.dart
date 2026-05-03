import 'dart:async';
import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/shaders/shaders_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/utils/vibrate.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/cupertino.dart' show MainAxisAlignment;
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../../http/requests/damaku_request.dart' show DanmakuRequest;
import '../video/video_ui_controller.dart' show VideoUiStateController;

class PlayState {
  /// 播放地址
  final String videoUrl;

  /// 播放偏移
  final int offset;

  /// 番剧id
  final int subjectId;

  ///番剧名称
  final String subjectName;

  ///番剧封面
  final String subjectCover;

  /// 集数
  final int episodeIndex;

  ///剧集id
  final int episodeId;

  const PlayState({
    required this.videoUrl,
    required this.offset,
    required this.subjectId,
    required this.episodeIndex,
    required this.episodeId,
    required this.subjectName,
    required this.subjectCover,
  });
}

class PlayController extends GetxController {
  late Player player;
  late VideoController videoController;
  final setting = Storage.setting;

  /// 视频超分
  /// 1. 关闭
  /// 2. 效率档
  /// 3. 质量档
  final superResolutionType = 0.obs;

  /// 宽屏状态
  final isWideScreen = false.obs;

  /// 内容区域展开状态
  final isContentExpanded = true.obs;

  /// 全屏状态
  final isFullscreen = false.obs;

  /// 视频地址
  String? videoUrl;

  /// 番剧名称
  String? animeTitle;

  /// 视频偏移
  int offset = 0;

  /// 番剧id
  int subjectId = 0;

  String? subjectCover;

  String? subjectName;

  /// 当前集数
  int episode = 0;

  ///剧集id
  int episodeId = 0;

  ///视频解析状态
  final isParsing = false.obs;

  ///视频解析结果
  final RxString parseResult = ''.obs;

  ///弹幕相关
  final RxMap<int, List<Danmaku>> danDanmakus = <int, List<Danmaku>>{}.obs;
  late DanmakuController danmakuController;
  final RxBool danmakuOn = true.obs;
  final RxSet<String> hiddenPlatforms = <String>{}.obs;
  Timer? _saveSettingsTimer;

  ///着色器
  late ShadersController shadersController;

  ///视频播放状态
  final RxBool playing = false.obs;

  ///视频播放进度
  final Rx<Duration> position = Duration.zero.obs;

  ///视频总时长
  final Rx<Duration> duration = Duration.zero.obs;

  ///视频缓冲
  final Rx<Duration> buffered = Duration.zero.obs;

  ///音量
  final RxDouble volume = 100.0.obs;

  /// 是否正在垂直拖动调整音量
  final RxBool isVerticalDragging = false.obs;
  final RxDouble rate = 1.0.obs;

  /// 缓冲状态
  final RxBool buffering = false.obs;

  /// 记录原始倍速
  double _originalSpeed = 1.0;

  /// 垂直拖动相关
  double _dragStartVolume = 100.0;

  /// 定时停止播放的计时器
  Timer? _stopTimer;

  /// 定时停止的时间（秒）
  final RxInt scheduledStopDuration = 0.obs;

  /// 弹幕相关
  bool _isLoadingDanmaku = false;
  bool _hasDanmakuLoaded = false;

  /// 定时保存播放进度的计时器
  Timer? _saveProgressTimer;

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);
    syncPlatformVisibilityFromStorage();
    shadersController = Get.find<ShadersController>();

    player.stream.playing.listen((playing) {
      this.playing.value = playing;
    });

    player.stream.volume.listen((vol) {
      volume.value = vol;
    });

    player.stream.buffer.listen((buffered) {
      this.buffered.value = buffered;
    });

    player.stream.buffering.listen((buffering) {
      this.buffering.value = buffering;
      _updateBufferingState(buffering);
    });

    player.stream.rate.listen((r) {
      rate.value = r;
    });

    player.stream.position.listen((pos) {
      position.value = pos;
    });

    player.stream.duration.listen((dur) {
      duration.value = dur;
    });
  }

  @override
  void onClose() {
    _saveSettingsTimer?.cancel();
    _saveProgressTimer?.cancel();
    _stopTimer?.cancel();
    player.dispose();
    super.onClose();
  }

  /// 初始化播放状态
  Future<void> initPlayState(PlayState state) async {
    videoUrl = state.videoUrl;
    offset = state.offset;
    subjectId = state.subjectId;
    episode = state.episodeIndex;
    episodeId = state.episodeId;
    subjectName = state.subjectName;
    subjectCover = state.subjectCover;
    if (state.videoUrl.isEmpty) return;
    await player.open(Media(state.videoUrl), play: false);
    await player.stream.duration.firstWhere((d) => d > Duration.zero);
    await Future.delayed(const Duration(milliseconds: 800), () {
      player.seek(Duration(seconds: offset));
    });
    await player.play();
    final logger = Logger();

    ///加载弹幕
    try {
      if (!_isLoadingDanmaku && episode != 0) {
        _isLoadingDanmaku = true;
        final bgmBangumiId =
            await DanmakuRequest.getDanDanBangumiIDByBgmBangumiID(subjectId);
        final danmaku =
            await DanmakuRequest.getDanDanmaku(bgmBangumiId, episode);
        logger.i('加载弹幕数:${danmaku.length}');
        addDanmaku(danmaku);
        _isLoadingDanmaku = false;
      }
    } catch (e) {
      logger.e(e);
    }

    /// 播放记录保存和章节进度更新
    _saveProgressTimer?.cancel();
    _saveProgressTimer = null;
    try {
      // 播放时，每5秒保存一次，使用实时获取的进度值
      _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final position = this.position.value;
        final duration = this.duration.value;
        // 播放进度大于0 && 播放时长大于0 开始保存剧集进度
        if (position != Duration.zero || duration != Duration.zero) {
          if (subjectId > 0 && episodeId > 0) {
            final playHistory = PlayHistory(
              subjectId: subjectId,
              subjectName: subjectName!,
              episodeId: episodeId,
              episodeSort: episode,
              cover: subjectCover!,
              updateAt: DateTime.now(),
              position: position.inSeconds,
              duration: duration.inSeconds,
            );
            PlayRepository.savePlayHistory(playHistory);
          }

          /// 播放进度大于90% && collection != null，更新章节进度
          final episodesProgress =
              setting.get(PlaybackKey.episodesProgress, defaultValue: true);
          if (episodesProgress) {
            final position = this.position.value;
            final duration = this.duration.value;
            final userInfoStore = Get.find<UserInfoStore>();
            if (userInfoStore.userInfo.value != null) {
              final progressPercent =
                  position.inSeconds / duration.inSeconds * 100;
              if (progressPercent > 90) {
                final currentIndex = episode - 1;
                final episodesState = Get.find<EpisodesState>();
                final episodes = episodesState.episodes.value;
                if (episodes != null &&
                    currentIndex >= 0 &&
                    currentIndex < episodes.data.length &&
                    episodes.data[currentIndex].collection == null) {
                  // TODO需要只有登录后才更新
                  UserRequest.updateEpisodeProgressService(episodeId,
                      batch: true, type: 2);
                  // TODO 同时更新本地剧集进度数据
                  logger.i('章节进度已更新: episodeId=$episodeId');
                }
              }
            }
          }
        }
      });
    } catch (e) {
      logger.e('保存播放进度失败: $e');
    }
  }

  ///更新缓冲状态
  void _updateBufferingState(bool buffering) {
    final videoUiStateController = Get.find<VideoUiStateController>();
    if (buffering) {
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.bufferingIndicator);
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController.showIndicator();
    } else {
      if (videoUiStateController.indicatorType.value ==
          VideoControlsIndicatorType.bufferingIndicator) {
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      }
    }
  }

  /// 从存储同步平台显示/隐藏状态
  void syncPlatformVisibilityFromStorage() {
    final Box setting = Storage.setting;

    // 读取各平台的显示设置
    final platformBilibili =
        setting.get(DanmakuKey.danmakuPlatformBilibili, defaultValue: true);
    final platformGamer =
        setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true);
    final platformDanDanPlay =
        setting.get(DanmakuKey.danmakuPlatformDanDanPlay, defaultValue: true);

    // 平台名称映射（从 source 字段中提取的实际名称，如 [BiliBili]、[Gamer]）
    const String platformNameBilibili = 'BiliBili';
    const String platformNameGamer = 'Gamer';
    const String platformNameDanDanPlay = '弹弹Play';

    // 根据设置更新 hiddenPlatforms
    if (!platformBilibili) {
      if (!hiddenPlatforms.contains(platformNameBilibili)) {
        hiddenPlatforms.add(platformNameBilibili);
      }
    } else {
      hiddenPlatforms.remove(platformNameBilibili);
    }

    if (!platformGamer) {
      if (!hiddenPlatforms.contains(platformNameGamer)) {
        hiddenPlatforms.add(platformNameGamer);
      }
    } else {
      hiddenPlatforms.remove(platformNameGamer);
    }

    if (!platformDanDanPlay) {
      if (!hiddenPlatforms.contains(platformNameDanDanPlay)) {
        hiddenPlatforms.add(platformNameDanDanPlay);
      }
    } else {
      hiddenPlatforms.remove(platformNameDanDanPlay);
    }

    // 同步后清空屏幕弹幕，让新设置生效
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  void updateIsWideScreen(bool value) {
    if (isWideScreen.value != value) {
      isWideScreen.value = value;
    }
  }

  // 切换内容区域展开状态
  void toggleContentExpanded() {
    isContentExpanded.value = !isContentExpanded.value;
  }

  /// 进入全屏
  void enterFullScreen() {
    isFullscreen.value = true;
    // 移动端全屏时自动横屏
    SystemUtil.enterFullScreen();
  }

  /// 退出全屏
  void exitFullScreen() {
    isFullscreen.value = false;
    SystemUtil.exitFullScreen();
  }

  /// 切换全屏状态
  void toggleFullScreen() {
    if (isFullscreen.value) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  /// 检测桌面端全屏状态
  Future<void> checkDesktopFullscreen() async {
    if (SystemUtil.isDesktop) {
      isFullscreen.value = await windowManager.isFullScreen();
    }
  }

  /// 处理全屏变化
  /// 在全屏切换时清空弹幕
  void handleFullscreenChange() {
    try {
      danmakuController.clear();
    } catch (_) {
      // 如果控制器未初始化，忽略错误
    }
  }

  void addDanmaku(List<Danmaku> danmaku) {
    // 按时间分组
    danDanmakus.clear();
    for (var item in danmaku) {
      int second = item.time.toInt();
      if (!danDanmakus.containsKey(second)) {
        danDanmakus[second] = [];
      }
      danDanmakus[second]!.add(item);
    }
  }

  void removeDanmaku() {
    danmakuController.clear();
    danDanmakus.clear();
  }

  /// 切换弹幕开关
  void toggleDanmaku() {
    danmakuOn.value = !danmakuOn.value;
    Storage.setting.put(DanmakuKey.danmakuOn, danmakuOn.value);
    if (!danmakuOn.value) {
      try {
        danmakuController.clear();
      } catch (_) {}
    }
  }

  /// 切换平台显示/隐藏状态
  void togglePlatformVisibility(String platform) {
    if (hiddenPlatforms.contains(platform)) {
      hiddenPlatforms.remove(platform);
    } else {
      hiddenPlatforms.add(platform);
    }
    // 清空屏幕上的弹幕，新弹幕会按照新的隐藏状态过滤
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  /// 检查平台是否被隐藏
  bool isPlatformHidden(String platform) {
    return hiddenPlatforms.contains(platform);
  }

  ///暂停|播放
  void playOrPauseVideo() {
    player.playOrPause();
  }

  ///设置播放倍数
  void startSpeedBoost(double speed) {
    _originalSpeed = rate.value;
    rate.value = speed;
    player.setRate(speed);
  }

  /// 跳转到指定位置
  void seekTo(Duration pos) {
    player.seek(pos);
  }

  /// 结束速度提升
  void endSpeedBoost() {
    rate.value = _originalSpeed;
    player.setRate(_originalSpeed);
  }

  ///设置视频音量（绝对值）
  void setVolume(double newVolume) {
    double clampedVolume = newVolume.clamp(0.0, 100.0);
    player.setVolume(clampedVolume);
  }

  void startVerticalDrag() {
    _dragStartVolume = volume.value;
    isVerticalDragging.value = true;
  }

  void adjustVolumeByWheel(double delta) {
    double newVolume = volume.value + delta;
    setVolume(newVolume);
  }

  void updateVerticalDrag(double dragDistance, double screenHeight) {
    final volumeChange = -(dragDistance / screenHeight) * 100;
    double newVolume = _dragStartVolume + volumeChange;
    if (newVolume >= 100 && volume.value < 100) {
      vibrateHeavy();
    } else if (newVolume <= 0 && volume.value > 0) {
      vibrateHeavy();
    }
    setVolume(newVolume);
  }

  void endVerticalDrag() {
    isVerticalDragging.value = false;
    Future.delayed(const Duration(seconds: 2), () {
      if (!isVerticalDragging.value) {}
    });
  }

  ///停止播放
  /// [duration] 可选参数，如果提供则会在指定时间后停止播放
  void stopPlaying({Duration? duration}) {
    _stopTimer?.cancel();

    if (duration != null && duration > Duration.zero) {
      final totalSeconds = duration.inSeconds;
      scheduledStopDuration.value = totalSeconds;

      _stopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (scheduledStopDuration.value > 0) {
          scheduledStopDuration.value--;
        } else {
          player.pause();
          timer.cancel();
          _stopTimer = null;
        }
      });
    } else {
      scheduledStopDuration.value = 0;
      player.pause();
    }
  }

  /// 取消定时停止
  void cancelScheduledStop() {
    _stopTimer?.cancel();
    _stopTimer = null;
    scheduledStopDuration.value = 0;
  }

  ///设置超分辨率
  /// type 1 关闭 2 效率档 3 质量档
  Future<void> setShader(int type) async {
    var pp = player.platform as NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    if (type == 2) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(shadersController.shadersDirectory.path,
            Constants.mpvAnime4KShadersLite),
      ]);
      superResolutionType.value = 2;
      return;
    }
    if (type == 3) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(shadersController.shadersDirectory.path,
            Constants.mpvAnime4KShaders),
      ]);
      superResolutionType.value = 3;
      return;
    }
    await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    superResolutionType.value = 1;
  }
}
