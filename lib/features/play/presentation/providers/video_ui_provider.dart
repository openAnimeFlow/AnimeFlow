import 'package:anime_flow/features/play/domain/playback_device.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/shared/widgets/windows_title_bar.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_ui_provider.g.dart';

class VideoUiState {
  const VideoUiState({
    this.isWideScreen = false,
    this.isContentExpanded = true,
    this.isFullscreen = false,
    this.isShowControlsUi = true,
    this.isHorizontalDragging = false,
    this.dragPosition = Duration.zero,
    this.topIndicator = VideoControlsIndicatorType.noIndicator,
    this.centerIndicator = VideoControlsIndicatorType.noIndicator,
    this.currentBrightness = 0.5,
    this.isBrightnessDragging = false,
    this.currentTime = '',
    this.batteryLevel = 0,
    this.charging = false,
    this.screenshotPreviewBytes,
  });

  final bool isWideScreen;
  final bool isContentExpanded;
  final bool isFullscreen;
  final bool isShowControlsUi;
  final bool isHorizontalDragging;
  final Duration dragPosition;
  final VideoControlsIndicatorType topIndicator;
  final VideoControlsIndicatorType centerIndicator;
  final double currentBrightness;
  final bool isBrightnessDragging;
  final String currentTime;
  final int batteryLevel;
  final bool charging;

  /// 最近一次截图的缩略图数据，为空表示不展示预览。
  final Uint8List? screenshotPreviewBytes;

  VideoUiState copyWith({
    bool? isWideScreen,
    bool? isContentExpanded,
    bool? isFullscreen,
    bool? isShowControlsUi,
    bool? isHorizontalDragging,
    Duration? dragPosition,
    VideoControlsIndicatorType? topIndicator,
    VideoControlsIndicatorType? centerIndicator,
    double? currentBrightness,
    bool? isBrightnessDragging,
    String? currentTime,
    int? batteryLevel,
    bool? charging,
    Uint8List? screenshotPreviewBytes,
    bool clearScreenshotPreview = false,
  }) {
    return VideoUiState(
      isWideScreen: isWideScreen ?? this.isWideScreen,
      isContentExpanded: isContentExpanded ?? this.isContentExpanded,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isShowControlsUi: isShowControlsUi ?? this.isShowControlsUi,
      isHorizontalDragging: isHorizontalDragging ?? this.isHorizontalDragging,
      dragPosition: dragPosition ?? this.dragPosition,
      topIndicator: topIndicator ?? this.topIndicator,
      centerIndicator: centerIndicator ?? this.centerIndicator,
      currentBrightness: currentBrightness ?? this.currentBrightness,
      isBrightnessDragging: isBrightnessDragging ?? this.isBrightnessDragging,
      currentTime: currentTime ?? this.currentTime,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      charging: charging ?? this.charging,
      screenshotPreviewBytes: clearScreenshotPreview
          ? null
          : screenshotPreviewBytes ?? this.screenshotPreviewBytes,
    );
  }
}

@Riverpod(dependencies: [playExtra, PlayStateNotifier])
class VideoUiNotifier extends _$VideoUiNotifier {
  Timer? _topIndicatorTimer;
  Timer? _controlsUiTimer;
  Timer? _timeUpdateTimer;
  Timer? _batteryUpdateTimer;
  Timer? _screenshotPreviewTimer;
  StreamSubscription<bool>? _chargingSubscription;
  late PlaybackDevice _device;

  double _originalBrightness = 0.5;
  double _dragStartX = 0;
  Duration _dragStartPosition = Duration.zero;
  double _dragStartBrightness = 0.5;
  int _runtimeRevision = 0;

  @override
  VideoUiState build() {
    // Route arguments establish ownership; UI state lasts for the route.
    ref.read(playExtraProvider);
    _device = ref.watch(playbackDeviceProvider);
    final revision = ++_runtimeRevision;
    ref.onDispose(_dispose);
    final initialState = VideoUiState(
      currentTime: _device.clockTime(),
    );
    state = initialState;
    // 展示层根据播放状态维护加载提示，业务会话不再持有 UI 操作接口。
    ref.listen(
      playStateProvider
          .select((value) => (phase: value.phase, buffering: value.buffering)),
      (previous, next) =>
          _syncPlaybackIndicator(previous?.phase, next.phase, next.buffering),
      fireImmediately: true,
    );
    unawaited(_initializeRuntimeState(revision));
    return state;
  }

  bool _isCurrentRuntime(int revision) =>
      ref.mounted && revision == _runtimeRevision;

  Future<void> _initializeRuntimeState(int revision) async {
    await _initializeBrightness(revision);
    if (!_isCurrentRuntime(revision)) return;
    _startTimeUpdate();
    await _initializeBattery(revision);
  }

  void setIsWideScreen(bool value) {
    if (state.isWideScreen == value) return;
    state = state.copyWith(isWideScreen: value);
  }

  void toggleContentExpanded() {
    state = state.copyWith(isContentExpanded: !state.isContentExpanded);
  }

  void setIsFullscreen(bool value) {
    state = state.copyWith(isFullscreen: value);
  }

  /// 进入全屏
  void enterFullScreen() {
    setIsFullscreen(true);
    if (_device.isWindows) {
      WindowsTitleBarVisibility.setForceHidden(true);
    }
    // 移动端全屏时自动横屏
    _device.enterFullScreen();
  }

  /// 退出全屏
  void exitFullScreen() {
    setIsFullscreen(false);
    if (_device.isWindows) {
      unawaited(_exitWindowsFullScreen());
    } else {
      _device.exitFullScreen();
    }
  }

  /// 先退出窗口全屏再恢复标题栏，避免 forceHidden 已 false 但 _windowFullScreen 仍为 true。
  Future<void> _exitWindowsFullScreen() async {
    final revision = _runtimeRevision;
    await _device.exitFullScreen();
    if (_isCurrentRuntime(revision)) {
      WindowsTitleBarVisibility.setForceHidden(false);
    }
  }

  /// 切换全屏状态
  void toggleFullScreen() {
    if (state.isFullscreen) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  /// 检测桌面端全屏状态
  Future<void> checkDesktopFullscreen() async {
    if (_device.isDesktop) {
      final revision = _runtimeRevision;
      final fullScreen = await _device.isFullScreen();
      if (!_isCurrentRuntime(revision)) return;
      setIsFullscreen(fullScreen);
      if (_device.isWindows) {
        WindowsTitleBarVisibility.setForceHidden(fullScreen);
      }
    }
  }

  void _dispose() {
    _runtimeRevision++;
    if (_device.isWindows) WindowsTitleBarVisibility.reset();
    _topIndicatorTimer?.cancel();
    _controlsUiTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _batteryUpdateTimer?.cancel();
    _screenshotPreviewTimer?.cancel();
    _chargingSubscription?.cancel();
    unawaited(_resetBrightness());
  }

  void _startTimeUpdate() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        currentTime: _device.clockTime(),
      );
    });
  }

  Future<void> _initializeBattery(int revision) async {
    await _updateBatteryInfo(revision);
    if (!_isCurrentRuntime(revision)) return;

    await _chargingSubscription?.cancel();
    if (!_isCurrentRuntime(revision)) return;
    _chargingSubscription = _device.chargingChanges.listen((state) {
      if (!_isCurrentRuntime(revision)) return;
      this.state = this.state.copyWith(charging: state);
      unawaited(_updateBatteryInfo(revision));
    });

    _batteryUpdateTimer?.cancel();
    _batteryUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_updateBatteryInfo(revision));
    });
  }

  Future<void> _updateBatteryInfo(int revision) async {
    try {
      final level = await _device.batteryLevel();
      if (!_isCurrentRuntime(revision)) return;
      final currentState = await _device.isCharging();
      if (!_isCurrentRuntime(revision)) return;
      state = state.copyWith(
        batteryLevel: level,
        charging: currentState,
      );
    } catch (_) {}
  }

  void showTopIndicator(
    VideoControlsIndicatorType type, {
    Duration? autoHide = const Duration(seconds: 3),
  }) {
    _topIndicatorTimer?.cancel();
    _topIndicatorTimer = null;
    if (state.topIndicator != type) {
      state = state.copyWith(topIndicator: type);
    }
    if (autoHide != null && autoHide > Duration.zero) {
      _topIndicatorTimer = Timer(autoHide, clearTopIndicator);
    }
  }

  void clearTopIndicator() {
    _topIndicatorTimer?.cancel();
    _topIndicatorTimer = null;
    if (state.topIndicator == VideoControlsIndicatorType.noIndicator) return;
    state = state.copyWith(
      topIndicator: VideoControlsIndicatorType.noIndicator,
    );
  }

  /// 手动选源时立即提示，后续由播放阶段变化接管。
  void showParsingIndicator() =>
      _setCenterIndicator(VideoControlsIndicatorType.parsingIndicator);

  void _syncPlaybackIndicator(
    PlaybackPhase? previousPhase,
    PlaybackPhase phase,
    bool buffering,
  ) {
    if (phase.keepsStartupIndicator) {
      showParsingIndicator();
      return;
    }
    var indicator = state.centerIndicator;
    if (indicator == VideoControlsIndicatorType.parsingIndicator) {
      // 手动选源可能先展示提示；阶段尚未变化时，旧媒体的缓冲事件不能将其覆盖。
      if (previousPhase == phase) return;
      indicator = VideoControlsIndicatorType.noIndicator;
    }
    final terminal = phase == PlaybackPhase.idle ||
        phase == PlaybackPhase.error ||
        phase == PlaybackPhase.completed;
    if (buffering && !terminal) {
      indicator = VideoControlsIndicatorType.bufferingIndicator;
    } else if (indicator == VideoControlsIndicatorType.bufferingIndicator) {
      indicator = VideoControlsIndicatorType.noIndicator;
    }
    _setCenterIndicator(indicator);
  }

  void _setCenterIndicator(VideoControlsIndicatorType type) {
    if (state.centerIndicator == type) return;
    state = state.copyWith(centerIndicator: type);
  }

  void showOrHideControlsUi() {
    state = state.copyWith(isShowControlsUi: !state.isShowControlsUi);
  }

  void showControlsUi() {
    state = state.copyWith(isShowControlsUi: true);
  }

  void restartControlsAutoHideTimer({
    Duration duration = const Duration(seconds: 3),
  }) {
    _controlsUiTimer?.cancel();
    showControlsUi();
    _controlsUiTimer = Timer(duration, () {
      state = state.copyWith(isShowControlsUi: false);
    });
  }

  void hideControlsUi({Duration? duration}) {
    _controlsUiTimer?.cancel();
    if (duration != null && duration > Duration.zero) {
      _controlsUiTimer = Timer(duration, () {
        state = state.copyWith(isShowControlsUi: false);
      });
    } else {
      state = state.copyWith(isShowControlsUi: false);
    }
  }

  /// 展示截图缩略图，[duration] 到期后自动隐藏。
  void showScreenshotPreview(
    Uint8List bytes, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _screenshotPreviewTimer?.cancel();
    state = state.copyWith(screenshotPreviewBytes: bytes);
    _screenshotPreviewTimer = Timer(duration, hideScreenshotPreview);
  }

  /// 隐藏截图缩略图。
  void hideScreenshotPreview() {
    _screenshotPreviewTimer?.cancel();
    _screenshotPreviewTimer = null;
    if (state.screenshotPreviewBytes == null) return;
    state = state.copyWith(clearScreenshotPreview: true);
  }

  void startHorizontalDrag(double startX, Duration position) {
    _dragStartX = startX;
    _dragStartPosition = position;
    state = state.copyWith(isHorizontalDragging: true);
    cancelUiTimer();
    showControlsUi();
  }

  void updateHorizontalDrag(
    double currentX,
    double scale,
    Duration duration,
  ) {
    if (duration <= Duration.zero) return;

    final dragDistance = currentX - _dragStartX;
    final timeOffset = dragDistance * scale;
    var newPosition = _dragStartPosition.inMilliseconds + timeOffset.toInt();
    newPosition = newPosition.clamp(0, duration.inMilliseconds);

    state = state.copyWith(
      dragPosition: Duration(milliseconds: newPosition),
    );
  }

  void startProgressDrag(Duration position) {
    state = state.copyWith(
      isHorizontalDragging: true,
      dragPosition: position,
    );
    cancelUiTimer();
    showControlsUi();
  }

  void setHorizontalDragPosition(Duration position) {
    state = state.copyWith(dragPosition: position);
  }

  void endHorizontalDrag() {
    if (state.isHorizontalDragging) {
      state = state.copyWith(isHorizontalDragging: false);
      restartControlsAutoHideTimer();
    }
  }

  void cancelHorizontalDrag() {
    if (state.isHorizontalDragging) {
      state = state.copyWith(
        isHorizontalDragging: false,
        dragPosition: _dragStartPosition,
      );
      hideControlsUi(duration: const Duration(seconds: 1));
    }
  }

  Future<void> _initializeBrightness(int revision) async {
    try {
      final brightness = await _device.brightness();
      if (!_isCurrentRuntime(revision)) return;
      _originalBrightness = brightness;
      state = state.copyWith(currentBrightness: brightness);
    } catch (_) {
      if (!_isCurrentRuntime(revision)) return;
      _originalBrightness = 0.5;
      state = state.copyWith(currentBrightness: 0.5);
    }
  }

  void startBrightnessDrag() {
    _dragStartBrightness = state.currentBrightness;
    state = state.copyWith(isBrightnessDragging: true);
    _controlsUiTimer?.cancel();
    showControlsUi();
    showTopIndicator(VideoControlsIndicatorType.brightnessIndicator);
  }

  void startBrightnessDragWithoutAutoHide() {
    _dragStartBrightness = state.currentBrightness;
    state = state.copyWith(isBrightnessDragging: true);
  }

  void setBrightnessDragging(bool value) {
    state = state.copyWith(isBrightnessDragging: value);
  }

  void updateBrightnessDrag(double dragDistance, double screenHeight) {
    final brightnessChange = -(dragDistance / screenHeight);
    final newBrightness =
        (_dragStartBrightness + brightnessChange).clamp(0.0, 1.0);

    if (newBrightness >= 1.0 && state.currentBrightness < 1.0) {
      _device.vibrateHeavy();
    } else if (newBrightness <= 0.0 && state.currentBrightness > 0.0) {
      _device.vibrateHeavy();
    }
    state = state.copyWith(currentBrightness: newBrightness);
    _device.setBrightness(newBrightness);
  }

  void endBrightnessDrag() {
    state = state.copyWith(isBrightnessDragging: false);
    clearTopIndicator();
    hideControlsUi(duration: const Duration(seconds: 1));
  }

  void cancelUiTimer() {
    _controlsUiTimer?.cancel();
  }

  Future<void> _resetBrightness() async {
    // Cleanup must not wait for another frame or write disposed provider state.
    final originalBrightness = _originalBrightness;
    try {
      await _device.resetBrightness();
    } catch (_) {
      try {
        await _device.setBrightness(originalBrightness);
      } catch (_) {}
    }
  }
}
