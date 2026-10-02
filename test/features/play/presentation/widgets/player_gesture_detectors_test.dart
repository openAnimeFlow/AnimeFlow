import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/gesture/desktop_gesture_detector.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/gesture/mobile_gesture_detector.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/control/middle_area_control.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _extra = PlayRouteExtra(
  playExtra: PlayExtra(
    subjectId: 1,
    subjectName: 'Subject',
    subjectCover: '',
    subjectAliases: [],
  ),
);

void main() {
  testWidgets('mobile gestures stay active above the indicator layer',
      (tester) async {
    final session = _Session();
    final container = _container(session);
    addTearDown(container.dispose);
    container.read(videoUiProvider.notifier)
      ..showCenterIndicator(VideoControlsIndicatorType.parsingIndicator)
      ..showTopIndicator(
        VideoControlsIndicatorType.playStatusIndicator,
        autoHide: null,
      );

    await tester.pumpWidget(_app(
      container,
      const MobileGestureDetector(child: MiddleAreaControl()),
    ));

    await _doubleTap(tester);

    // 冲掉手势提示的自动隐藏计时器。
    await tester.pump(const Duration(seconds: 4));
    expect(session.toggles, 1);
  });

  testWidgets('desktop gestures stay active above the indicator layer',
      (tester) async {
    final session = _Session();
    final container = _container(session);
    addTearDown(container.dispose);
    container.read(videoUiProvider.notifier)
      ..showCenterIndicator(VideoControlsIndicatorType.parsingIndicator)
      ..showTopIndicator(
        VideoControlsIndicatorType.playStatusIndicator,
        autoHide: null,
      );

    await tester.pumpWidget(_app(
      container,
      const DesktopGestureDetector(child: MiddleAreaControl()),
    ));

    // 单击要等双击窗口结束才会派发。
    await _tapPlayer(tester);
    await tester.pump(const Duration(milliseconds: 400));

    // 冲掉手势提示的自动隐藏计时器。
    await tester.pump(const Duration(seconds: 4));
    expect(session.toggles, 1);
  });
}

Widget _app(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 400, height: 300, child: child),
        ),
      ),
    ),
  );
}

ProviderContainer _container(_Session session) => ProviderContainer(overrides: [
      playExtraProvider.overrideWithValue(_extra),
      playSessionProvider.overrideWithValue(session),
      videoUiProvider.overrideWith(_TestVideoUiNotifier.new),
    ]);

Future<void> _doubleTap(WidgetTester tester) async {
  await _tapPlayer(tester);
  await tester.pump(const Duration(milliseconds: 50));
  await _tapPlayer(tester);
  await tester.pump(const Duration(milliseconds: 400));
}

/// 点在指示器范围之外，验证整块播放区域仍能响应手势。
Future<void> _tapPlayer(WidgetTester tester) async {
  final rect = tester.getRect(find.byType(MiddleAreaControl));
  await tester.tapAt(
    Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.25),
  );
}

class _Session implements PlaySession {
  int toggles = 0;

  @override
  bool playOrPauseVideo() {
    toggles++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestVideoUiNotifier extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();
}
