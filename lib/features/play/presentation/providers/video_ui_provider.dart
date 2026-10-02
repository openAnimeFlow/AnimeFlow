import 'dart:async';

import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/vibrate.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

part 'video_ui_provider.g.dart';

abstract class VideoUiStateActions {
  void restartControlsAutoHideTimer({
    Duration duration = const Duration(seconds: 3),
  });

  /// 顶部提示：展示 [type]；[autoHide] 到期后自动清除，为空表示保持到显式清除。
  void showTopIndicator(
    VideoControlsIndicatorType type, {
    Duration? autoHide = const Duration(seconds: 3),
  });

  /// 清除顶部提示。
  void clearTopIndicator();

  /// 居中指示器，可长期驻留（解析、缓冲、拖动进度）。
  void showCenterIndicator(VideoControlsIndicatorType type);

  /// 清除居中指示器。
  void clearCenterIndicator();

  VideoControlsIndicatorType get topIndicator;

  VideoControlsIndicatorType get centerIndicator;
}

extension PlaybackLoadingIndicators on VideoUiStateActions {
  void showParsingIndicator() =>
      showCenterIndicator(VideoControlsIndicatorType.parsingIndicator);

  /// 解析结果落定后才释放解析指示器。
  void finishParsingIndicator() {
    if (centerIndicator == VideoControlsIndicatorType.parsingIndicator) {
      clearCenterIndicator();
    }
  }

  void updateBufferingIndicator(bool buffering, {required bool isParsing}) {
    // Resource selection can show parsing before the resolver sets isParsing.
    // Only the parse result handler should dismiss that indicator.
    if (isParsing) {
      showParsingIndicator();
      return;
    }
    if (centerIndicator == VideoControlsIndicatorType.parsingIndicator) {
      return;
    }
    if (buffering) {
      showCenterIndicator(VideoControlsIndicatorType.bufferingIndicator);
    } else if (centerIndicator ==
        VideoControlsIndicatorType.bufferingIndicator) {
      clearCenterIndicator();
    }
  }
}

class VideoUiState {
  const VideoUiState({
    this.isShowControlsUi = true,
    this.isHorizontalDragging = false,
    this.dragPosition = Duration.zero,
    this.topIndicator = VideoControlsIndicatorType.noIndicator,
    this.centerIndicator = VideoControlsIndicatorType.noIndicator,
    this.currentBrightness = 0.5,
    this.isBrightnessDragging = false,
    this.currentTime = '',
    this.batteryLevel = 0,
    this.batteryState = BatteryState.unknown,
  });

  final bool isShowControlsUi;
  final bool isHorizontalDragging;
  final Duration dragPosition;
  final VideoControlsIndicatorType topIndicator;
  final VideoControlsIndicatorType centerIndicator;
  final double currentBrightness;
  final bool isBrightnessDragging;
  final String currentTime;
  final int batteryLevel;
  final BatteryState batteryState;

  VideoUiState copyWith({
    bool? isShowControlsUi,
    bool? isHorizontalDragging,
    Duration? dragPosition,
    VideoControlsIndicatorType? topIndicator,
    VideoControlsIndicatorType? centerIndicator,
    double? currentBrightness,
    bool? isBrightnessDragging,
    String? currentTime,
    int? batteryLevel,
    BatteryState? batteryState,
  }) {
    return VideoUiState(
      isShowControlsUi: isShowControlsUi ?? this.isShowControlsUi,
      isHorizontalDragging: isHorizontalDragging ?? this.isHorizontalDragging,
      dragPosition: dragPosition ?? this.dragPosition,
      topIndicator: topIndicator ?? this.topIndicator,
      centerIndicator: centerIndicator ?? this.centerIndicator,
      currentBrightness: currentBrightness ?? this.currentBrightness,
      isBrightnessDragging: isBrightnessDragging ?? this.isBrightnessDragging,
      currentTime: currentTime ?? this.currentTime,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryState: batteryState ?? this.batteryState,
    );
  }
}

// Keep controls alive while hidden, but own them in the playback route scope.
@Riverpod(keepAlive: true, dependencies: [playExtra])
class VideoUiNotifier extends _$VideoUiNotifier implements VideoUiStateActions {
  Timer? _topIndicatorTimer;
  Timer? _controlsUiTimer;
  Timer? _timeUpdateTimer;
  Timer? _batteryUpdateTimer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  final ScreenBrightnessPlatform _screenBrightness =
      ScreenBrightnessPlatform.instance;

  double _originalBrightness = 0.5;
  double _dragStartX = 0;
  Duration _dragStartPosition = Duration.zero;
  double _dragStartBrightness = 0.5;
  int _runtimeRevision = 0;

  bool get isShowControlsUi => state.isShowControlsUi;
  bool get isHorizontalDragging => state.isHorizontalDragging;
  Duration get dragPosition => state.dragPosition;
  @override
  VideoControlsIndicatorType get topIndicator => state.topIndicator;
  @override
  VideoControlsIndicatorType get centerIndicator => state.centerIndicator;
  double get currentBrightness => state.currentBrightness;
  bool get isBrightnessDragging => state.isBrightnessDragging;
  String get currentTime => state.currentTime;
  int get batteryLevel => state.batteryLevel;
  BatteryState get batteryState => state.batteryState;

  @override
  VideoUiState build() {
    // Route arguments establish ownership; UI state lasts for the route.
    ref.read(playExtraProvider);
    final revision = ++_runtimeRevision;
    ref.onDispose(_dispose);
    final initialState = VideoUiState(
      currentTime: SystemUtil.getCurrentTimeWithoutSeconds(),
    );
    state = initialState;
    unawaited(_initializeRuntimeState(revision));
    return initialState;
  }

  bool _isCurrentRuntime(int revision) =>
      ref.mounted && revision == _runtimeRevision;

  Future<void> _initializeRuntimeState(int revision) async {
    await _initializeBrightness(revision);
    if (!_isCurrentRuntime(revision)) return;
    _startTimeUpdate();
    await _initializeBattery(revision);
  }

  void _dispose() {
    _runtimeRevision++;
    _topIndicatorTimer?.cancel();
    _controlsUiTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _batteryUpdateTimer?.cancel();
    _batteryStateSubscription?.cancel();
    unawaited(_resetBrightness());
  }

  void _startTimeUpdate() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        currentTime: SystemUtil.getCurrentTimeWithoutSeconds(),
      );
    });
  }

  Future<void> _initializeBattery(int revision) async {
    await _updateBatteryInfo(revision);
    if (!_isCurrentRuntime(revision)) return;

    await _batteryStateSubscription?.cancel();
    if (!_isCurrentRuntime(revision)) return;
    _batteryStateSubscription = SystemUtil.batteryStateStream.listen((state) {
      if (!_isCurrentRuntime(revision)) return;
      this.state = this.state.copyWith(batteryState: state);
      unawaited(_updateBatteryInfo(revision));
    });

    _batteryUpdateTimer?.cancel();
    _batteryUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_updateBatteryInfo(revision));
    });
  }

  Future<void> _updateBatteryInfo(int revision) async {
    try {
      final level = await SystemUtil.getBatteryLevel();
      if (!_isCurrentRuntime(revision)) return;
      final currentState = await SystemUtil.getBatteryState();
      if (!_isCurrentRuntime(revision)) return;
      state = state.copyWith(
        batteryLevel: level,
        batteryState: currentState,
      );
    } catch (_) {}
  }

  @override
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

  @override
  void clearTopIndicator() {
    _topIndicatorTimer?.cancel();
    _topIndicatorTimer = null;
    if (state.topIndicator == VideoControlsIndicatorType.noIndicator) return;
    state = state.copyWith(
      topIndicator: VideoControlsIndicatorType.noIndicator,
    );
  }

  @override
  void showCenterIndicator(VideoControlsIndicatorType type) {
    if (state.centerIndicator == type) return;
    state = state.copyWith(centerIndicator: type);
  }

  @override
  void clearCenterIndicator() {
    if (state.centerIndicator == VideoControlsIndicatorType.noIndicator) {
      return;
    }
    state = state.copyWith(
      centerIndicator: VideoControlsIndicatorType.noIndicator,
    );
  }

  void showOrHideControlsUi() {
    state = state.copyWith(isShowControlsUi: !state.isShowControlsUi);
  }

  void showControlsUi() {
    state = state.copyWith(isShowControlsUi: true);
  }

  @override
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
      hideControlsUi(duration: const Duration(seconds: 1));
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
      final brightness = await _screenBrightness.application;
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
      vibrateHeavy();
    } else if (newBrightness <= 0.0 && state.currentBrightness > 0.0) {
      vibrateHeavy();
    }
    state = state.copyWith(currentBrightness: newBrightness);
    _screenBrightness.setApplicationScreenBrightness(newBrightness);
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
      await _screenBrightness.resetApplicationScreenBrightness();
    } catch (_) {
      try {
        await _screenBrightness
            .setApplicationScreenBrightness(originalBrightness);
      } catch (_) {}
    }
  }
}
