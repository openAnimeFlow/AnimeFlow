import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('old notification timer cannot hide parsing', (tester) async {
    final container = ProviderContainer(overrides: [
      videoUiProvider.overrideWith(_TestVideoUiNotifier.new),
    ]);
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);
    ui.updateIndicatorTypeAndShowIndicator(
      VideoControlsIndicatorType.playStatusIndicator,
    );
    await tester.pump(const Duration(seconds: 1));
    ui.showParsingIndicator();
    await tester.pump(const Duration(seconds: 4));
    expect(
        ui.currentIndicatorType, VideoControlsIndicatorType.parsingIndicator);
    expect(ui.isShowIndicatorUi, isTrue);
  });

  testWidgets('gesture notifications and cleanup cannot dismiss parsing',
      (tester) async {
    final container = ProviderContainer(overrides: [
      videoUiProvider.overrideWith(_TestVideoUiNotifier.new),
    ]);
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);
    ui.showParsingIndicator();
    for (final type in [
      VideoControlsIndicatorType.playStatusIndicator,
      VideoControlsIndicatorType.volumeIndicator,
      VideoControlsIndicatorType.brightnessIndicator,
    ]) {
      ui.updateIndicatorTypeAndShowIndicator(type);
      ui.hideIndicator();
      ui.updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      ui.updateMainAxisAlignmentType(MainAxisAlignment.start);
      await tester.pump(const Duration(seconds: 4));
      expect(
          ui.currentIndicatorType, VideoControlsIndicatorType.parsingIndicator);
      expect(ui.isShowIndicatorUi, isTrue);
      expect(ui.mainAxisAlignmentType, MainAxisAlignment.center);
    }
    // Resolver errors set isParsing=false; this must not release the message.
    ui.updateBufferingIndicator(false, isParsing: false);
    expect(ui.isShowIndicatorUi, isTrue);
    expect(
        ui.currentIndicatorType, VideoControlsIndicatorType.parsingIndicator);

    ui.finishParsingIndicator();
    expect(ui.isShowIndicatorUi, isFalse);
    expect(ui.currentIndicatorType, VideoControlsIndicatorType.noIndicator);
    ui.updateIndicatorTypeAndShowIndicator(
      VideoControlsIndicatorType.playStatusIndicator,
    );
    expect(ui.currentIndicatorType,
        VideoControlsIndicatorType.playStatusIndicator);
    await tester.pump(const Duration(seconds: 4));
    expect(ui.isShowIndicatorUi, isFalse);
  });

  test('source parsing replaces an existing buffering indicator', () {
    final ui = _Indicators();
    ui.updateBufferingIndicator(true, isParsing: false);
    ui.showParsingIndicator();
    expect(
        ui.currentIndicatorType, VideoControlsIndicatorType.parsingIndicator);
    expect(ui.visible, isTrue);
  });

  test('buffering callbacks cannot replace or hide source parsing', () {
    for (final isParsing in [false, true]) {
      final ui = _Indicators()..showParsingIndicator();
      for (final buffering in [true, false, true]) {
        ui.updateBufferingIndicator(buffering, isParsing: isParsing);
        expect(ui.currentIndicatorType,
            VideoControlsIndicatorType.parsingIndicator);
        expect(ui.visible, isTrue);
      }
    }
  });

  test('active parsing restores its indicator after another UI indicator', () {
    final ui = _Indicators();
    ui.updateIndicatorType(VideoControlsIndicatorType.playStatusIndicator);
    ui.updateBufferingIndicator(true, isParsing: true);
    expect(
        ui.currentIndicatorType, VideoControlsIndicatorType.parsingIndicator);
    expect(ui.visible, isTrue);
  });

  test('after parsing, actual buffering is shown and dismissed on recovery',
      () {
    final ui = _Indicators()..showParsingIndicator();
    // The parse success handler releases the parsing indicator.
    ui.finishParsingIndicator();
    ui.updateBufferingIndicator(true, isParsing: false);
    expect(
        ui.currentIndicatorType, VideoControlsIndicatorType.bufferingIndicator);
    expect(ui.visible, isTrue);
    ui.updateBufferingIndicator(false, isParsing: false);
    expect(ui.currentIndicatorType, VideoControlsIndicatorType.noIndicator);
    expect(ui.visible, isFalse);
    expect(ui.alignment, MainAxisAlignment.start);
  });
}

class _Indicators implements VideoUiStateActions {
  @override
  VideoControlsIndicatorType currentIndicatorType =
      VideoControlsIndicatorType.noIndicator;
  bool visible = false;
  MainAxisAlignment alignment = MainAxisAlignment.start;

  @override
  void updateIndicatorType(VideoControlsIndicatorType type) {
    currentIndicatorType = type;
  }

  @override
  void updateMainAxisAlignmentType(MainAxisAlignment type) => alignment = type;

  @override
  void showIndicator() => visible = true;

  @override
  void hideIndicator() => visible = false;

  @override
  void finishParsingIndicator() {
    visible = false;
    currentIndicatorType = VideoControlsIndicatorType.noIndicator;
    alignment = MainAxisAlignment.start;
  }
}

// Exercise the production indicator methods without platform battery or
// brightness initialization and its unrelated periodic timers.
class _TestVideoUiNotifier extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();
}
