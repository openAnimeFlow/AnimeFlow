import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/play_pause_icon.dart';
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
  testWidgets('top and center indicators render on independent layers',
      (tester) async {
    final container = ProviderContainer(overrides: [
      playExtraProvider.overrideWithValue(_extra),
      videoUiProvider.overrideWith(_TestVideoUiNotifier.new),
    ]);
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);
    ui.showCenterIndicator(VideoControlsIndicatorType.parsingIndicator);
    ui.showTopIndicator(
      VideoControlsIndicatorType.playStatusIndicator,
      autoHide: null,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: MiddleAreaControl(),
              ),
            ),
          ),
        ),
      ),
    );

    final spinner = find.byType(CircularProgressIndicator);
    final playIcon = find.byType(PlayPauseIcon);
    expect(spinner, findsOneWidget);
    expect(playIcon, findsOneWidget);

    // 居中指示器位于画面中心，顶部提示位于顶部保留间距处。
    final video = tester.getRect(find.byType(MiddleAreaControl));
    expect(
      tester.getCenter(spinner).dy,
      moreOrLessEquals(video.center.dy, epsilon: 30),
    );
    expect(tester.getCenter(playIcon).dy, lessThan(video.center.dy));
    expect(tester.getCenter(playIcon).dy - video.top, lessThan(100));
  });
}

class _TestVideoUiNotifier extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();
}
