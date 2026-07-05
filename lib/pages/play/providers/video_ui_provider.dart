import 'dart:async';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/vibrate.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

part 'video_ui_provider.g.dart';

abstract class VideoUiStateActions {
  void updateMainAxisAlignmentType(MainAxisAlignment type);

  void updateIndicatorType(VideoControlsIndicatorType type);

  void showIndicator();

  void hideIndicator();

  VideoControlsIndicatorType get currentIndicatorType;
}

class VideoUiState {
  const VideoUiState({
    this.isShowControlsUi = true,
    this.isHorizontalDragging = false,
    this.dragPosition = Duration.zero,
    this.isShowIndicatorUi = false,
    this.indicatorType = VideoControlsIndicatorType.noIndicator,
    this.mainAxisAlignmentType = MainAxisAlignment.start,
    this.currentBrightness = 0.5,
    this.isBrightnessDragging = false,
    this.currentTime = '',
    this.batteryLevel = 0,
    this.batteryState = BatteryState.unknown,
  });

  final bool isShowControlsUi;
  final bool isHorizontalDragging;
  final Duration dragPosition;
  final bool isShowIndicatorUi;
  final VideoControlsIndicatorType indicatorType;
  final MainAxisAlignment mainAxisAlignmentType;
  final double currentBrightness;
  final bool isBrightnessDragging;
  final String currentTime;
  final int batteryLevel;
  final BatteryState batteryState;

  VideoUiState copyWith({
    bool? isShowControlsUi,
    bool? isHorizontalDragging,
    Duration? dragPosition,
    bool? isShowIndicatorUi,
    VideoControlsIndicatorType? indicatorType,
    MainAxisAlignment? mainAxisAlignmentType,
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
      isShowIndicatorUi: isShowIndicatorUi ?? this.isShowIndicatorUi,
      indicatorType: indicatorType ?? this.indicatorType,
      mainAxisAlignmentType:
          mainAxisAlignmentType ?? this.mainAxisAlignmentType,
      currentBrightness: currentBrightness ?? this.currentBrightness,
      isBrightnessDragging: isBrightnessDragging ?? this.isBrightnessDragging,
      currentTime: currentTime ?? this.currentTime,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      batteryState: batteryState ?? this.batteryState,
    );
  }
}

@Riverpod(keepAlive: true)
class VideoUiStateController extends _$VideoUiStateController
    implements VideoUiStateActions {
  Timer? _indicatorTimer;
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
  bool _initialized = false;

  bool get isShowControlsUi => state.isShowControlsUi;
  bool get isHorizontalDragging => state.isHorizontalDragging;
  Duration get dragPosition => state.dragPosition;
  bool get isShowIndicatorUi => state.isShowIndicatorUi;
  VideoControlsIndicatorType get indicatorType => state.indicatorType;
  @override
  VideoControlsIndicatorType get currentIndicatorType => state.indicatorType;
  MainAxisAlignment get mainAxisAlignmentType => state.mainAxisAlignmentType;
  double get currentBrightness => state.currentBrightness;
  bool get isBrightnessDragging => state.isBrightnessDragging;
  String get currentTime => state.currentTime;
  int get batteryLevel => state.batteryLevel;
  BatteryState get batteryState => state.batteryState;

  @override
  VideoUiState build() {
    ref.onDispose(_dispose);
    final initialState = VideoUiState(
      currentTime: SystemUtil.getCurrentTimeWithoutSeconds(),
    );
    state = initialState;
    if (!_initialized) {
      _initialized = true;
      unawaited(_initializeRuntimeState());
    }
    return initialState;
  }

  Future<void> _initializeRuntimeState() async {
    await _initializeBrightness();
    _startTimeUpdate();
    await _initializeBattery();
  }

  void _dispose() {
    _indicatorTimer?.cancel();
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

  Future<void> _initializeBattery() async {
    await _updateBatteryInfo();

    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = SystemUtil.batteryStateStream.listen((state) {
      this.state = this.state.copyWith(batteryState: state);
      _updateBatteryInfo();
    });

    _batteryUpdateTimer?.cancel();
    _batteryUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateBatteryInfo();
    });
  }

  Future<void> _updateBatteryInfo() async {
    try {
      final level = await SystemUtil.getBatteryLevel();
      final currentState = await SystemUtil.getBatteryState();
      state = state.copyWith(
        batteryLevel: level,
        batteryState: currentState,
      );
    } catch (_) {}
  }

  @override
  void updateMainAxisAlignmentType(MainAxisAlignment type) {
    if (state.mainAxisAlignmentType != type) {
      state = state.copyWith(mainAxisAlignmentType: type);
    }
  }

  void updateIndicatorTypeAndShowIndicator(VideoControlsIndicatorType type) {
    state = state.copyWith(indicatorType: type);
    _showIndicatorSetUp();
  }

  @override
  void updateIndicatorType(VideoControlsIndicatorType type) {
    if (state.indicatorType != type) {
      state = state.copyWith(indicatorType: type);
    }
  }

  @override
  void showIndicator() {
    _indicatorTimer?.cancel();
    state = state.copyWith(isShowIndicatorUi: true);
  }

  @override
  void hideIndicator() {
    _indicatorTimer?.cancel();
    state = state.copyWith(isShowIndicatorUi: false);
  }

  void _showIndicatorSetUp() {
    _indicatorTimer?.cancel();
    state = state.copyWith(isShowIndicatorUi: true);
    _indicatorTimer = Timer(const Duration(seconds: 3), () {
      state = state.copyWith(
        isShowIndicatorUi: false,
        indicatorType: VideoControlsIndicatorType.noIndicator,
        mainAxisAlignmentType: MainAxisAlignment.start,
      );
    });
  }

  void showOrHideControlsUi() {
    state = state.copyWith(isShowControlsUi: !state.isShowControlsUi);
  }

  void showControlsUi() {
    state = state.copyWith(isShowControlsUi: true);
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

  Future<void> _initializeBrightness() async {
    try {
      final brightness = await _screenBrightness.application;
      _originalBrightness = brightness;
      state = state.copyWith(currentBrightness: brightness);
    } catch (_) {
      _originalBrightness = 0.5;
      state = state.copyWith(currentBrightness: 0.5);
    }
  }

  void startBrightnessDrag() {
    _dragStartBrightness = state.currentBrightness;
    state = state.copyWith(isBrightnessDragging: true);
    _controlsUiTimer?.cancel();
    showControlsUi();
    updateIndicatorTypeAndShowIndicator(
      VideoControlsIndicatorType.brightnessIndicator,
    );
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
    hideIndicator();
    updateIndicatorType(VideoControlsIndicatorType.noIndicator);
    updateMainAxisAlignmentType(MainAxisAlignment.start);
    hideControlsUi(duration: const Duration(seconds: 1));
  }

  void cancelUiTimer() {
    _controlsUiTimer?.cancel();
  }

  Future<void> _resetBrightness() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _screenBrightness.resetApplicationScreenBrightness();
        state = state.copyWith(currentBrightness: _originalBrightness);
      } catch (_) {
        try {
          await _screenBrightness
              .setApplicationScreenBrightness(_originalBrightness);
          state = state.copyWith(currentBrightness: _originalBrightness);
        } catch (_) {}
      }
    });
  }
}
