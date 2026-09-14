import 'dart:async';

import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/domain/player/player_shortcut.dart';
import 'package:anime_flow/features/play/presentation/providers/play_content_actions.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/recommendation_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/play_content_navigator.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/gesture/desktop_gesture_detector.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

class _Settings implements Box<dynamic> {
  final storedValues = <dynamic, dynamic>{};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      storedValues[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async =>
      storedValues[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Keep external data pending: the real introduction/detail widgets and navigator
// are mounted, but tests do not need networking, storage or a video engine.
class _Info extends AnimeInfo {
  @override
  Future<SubjectsInfoItem> build() => Completer<SubjectsInfoItem>().future;
}

class _Episodes extends Episodes {
  @override
  Future<EpisodesData> build() async => const EpisodesData(subjectId: 1);
}

class _PlayState extends PlayStateNotifier {
  @override
  PlayState build() => const PlayState();
}

class _Sources extends VideoSourceNotifier {
  @override
  VideoSourceState build() => const VideoSourceState();
}

class _Session implements PlaySession {
  int toggles = 0;
  final actions = <PlayerShortcutAction>[];
  final seeks = <Duration>[];
  final volumeChanges = <double>[];

  @override
  void seekTo(Duration position) => seeks.add(position);

  @override
  void adjustVolumeByWheel(double delta) => volumeChanges.add(delta);

  @override
  void playOrPauseVideo() => toggles++;

  @override
  void toggleFullScreen() => actions.add(PlayerShortcutAction.enterFullscreen);

  @override
  void exitFullScreen() => actions.add(PlayerShortcutAction.exitFullscreen);

  @override
  Future<Uint8List?> takeScreenshot() async {
    actions.add(PlayerShortcutAction.screenshot);
    return null;
  }

  @override
  void toggleDanmaku() => actions.add(PlayerShortcutAction.toggleDanmaku);

  @override
  void switchToNextEpisode() => actions.add(PlayerShortcutAction.nextEpisode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VideoUi extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();

  @override
  void updateIndicatorTypeAndShowIndicator(VideoControlsIndicatorType type) {}
}

class _Actions extends PlayContentActions {
  _Actions(super.ref);
  final completion = Completer<void>();
  int calls = 0;
  @override
  Future<void> resume() {
    calls++;
    return completion.future;
  }
}

class _Host extends StatefulWidget {
  const _Host({super.key});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final tabs = TabController(length: 2, vsync: this);
  bool hidden = false;
  void hide(bool value) => setState(() => hidden = value);
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Player host')),
        body: Offstage(
          offstage: hidden,
          child: TickerMode(
            enabled: !hidden,
            child: AnimatedBuilder(
              animation: tabs,
              builder: (context, child) => Column(children: [
                const DesktopGestureDetector(
                  child: SizedBox(
                    width: 200,
                    height: 80,
                    child: ColoredBox(color: Colors.black),
                  ),
                ),
                TabBar(controller: tabs, tabs: const [
                  Tab(text: 'Intro tab'),
                  Tab(text: 'Comments tab')
                ]),
                Expanded(
                    child: TabBarView(controller: tabs, children: [
                  PlayContentNavigator(isActive: tabs.index == 0 && !hidden),
                  const Center(child: Text('Comments content')),
                ])),
              ]),
            ),
          ),
        ),
      );
}

Future<void> _frames(WidgetTester tester) async {
  // Pending network placeholders animate indefinitely, so do not pumpAndSettle.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

void main() {
  final settings = _Settings();
  setUpAll(() => Storage.setting = settings);
  setUp(() => settings.storedValues.clear());

  late GoRouter router;
  late GlobalKey<_HostState> host;
  late _Actions actions;
  late _Session session;
  Future<void> mount(WidgetTester tester) async {
    host = GlobalKey<_HostState>();
    router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home'))),
      GoRoute(path: '/player', builder: (context, state) => _Host(key: host)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          animeInfoArgsProvider.overrideWithValue(
              InfoRouteExtra(id: 1, name: 'Test subject', image: '')),
          playExtraProvider.overrideWithValue(const PlayRouteExtra(
              playExtra: PlayExtra(
                  subjectId: 1,
                  subjectName: 'Test subject',
                  subjectCover: '',
                  subjectAliases: []))),
          animeInfoProvider.overrideWith(_Info.new),
          episodesProvider.overrideWith(_Episodes.new),
          playStateProvider.overrideWith(_PlayState.new),
          playSessionProvider.overrideWithValue(session = _Session()),
          videoUiProvider.overrideWith(_VideoUi.new),
          videoSourceProvider.overrideWith(_Sources.new),
          isLoggedInProvider.overrideWith((ref) async => false),
          recommendationProvider
              .overrideWith((ref) => Completer<SubjectItem>().future),
          playContentActionsProvider
              .overrideWith((ref) => actions = _Actions(ref)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        )));
    router.push<void>('/player');
    await _frames(tester);
    expect(find.byType(PlayContentNavigator), findsOneWidget);
  }

  Future<void> details(WidgetTester tester) async {
    await tester.tap(find.text('Test subject').first);
    await _frames(tester);
    expect(find.byType(AnimeInfoView), findsOneWidget);
  }

  Future<void> scrollPlayer(WidgetTester tester, Offset delta) async {
    await tester.sendEventToBinding(PointerScrollEvent(
      position: tester.getCenter(find.byType(DesktopGestureDetector)),
      scrollDelta: delta,
    ));
  }

  for (final action in PlayerShortcutAction.values) {
    for (final delta in [-20.0, 20.0]) {
      testWidgets('wheel $delta executes saved ${action.name} binding',
          (tester) async {
        // Free both default wheel bindings, as the editor does before reassignment.
        for (final volumeAction in [
          PlayerShortcutAction.volumeUp,
          PlayerShortcutAction.volumeDown,
        ]) {
          volumeAction.saveBindings(volumeAction.defaultBindings
              .where((binding) => !binding.isWheel)
              .toList());
        }
        action.saveBindings([PlayerShortcutBinding.wheel(delta < 0 ? 5 : -5)]);
        await mount(tester);
        await scrollPlayer(tester, Offset(0, delta));
        expect(
            session.toggles, action == PlayerShortcutAction.playPause ? 1 : 0);
        expect(
            session.seeks.length,
            [
              PlayerShortcutAction.seekBackward,
              PlayerShortcutAction.seekForward
            ].contains(action)
                ? 1
                : 0);
        expect(
            session.volumeChanges,
            switch (action) {
              PlayerShortcutAction.volumeUp => [5.0],
              PlayerShortcutAction.volumeDown => [-5.0],
              _ => isEmpty,
            });
        expect(
            session.actions,
            switch (action) {
              PlayerShortcutAction.enterFullscreen ||
              PlayerShortcutAction.exitFullscreen ||
              PlayerShortcutAction.screenshot ||
              PlayerShortcutAction.toggleDanmaku ||
              PlayerShortcutAction.nextEpisode =>
                [action],
              _ => isEmpty,
            });
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
      'default wheels adjust volume and horizontal scrolling is ignored',
      (tester) async {
    await mount(tester);
    await scrollPlayer(tester, const Offset(0, -20));
    await scrollPlayer(tester, const Offset(0, 20));
    await scrollPlayer(tester, const Offset(20, 0));
    await scrollPlayer(tester, const Offset(-20, 0));
    expect(session.volumeChanges, [5.0, -5.0]);
  });

  testWidgets('removed wheel binding is ignored', (tester) async {
    PlayerShortcutAction.volumeUp.saveBindings([
      const PlayerShortcutBinding.keyboard(LogicalKeyboardKey.arrowUp),
    ]);
    await mount(tester);
    await scrollPlayer(tester, const Offset(0, -20));
    expect(session.volumeChanges, isEmpty);
    expect(session.toggles, 0);
    expect(session.seeks, isEmpty);
    expect(session.actions, isEmpty);
  });

  testWidgets('introduction does not steal initial player keyboard focus',
      (tester) async {
    await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(session.toggles, 1);
    await details(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(session.toggles, 2);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(session.toggles, 3);
  });

  for (final key in [
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  ]) {
    testWidgets(
        '${key.keyLabel} keeps player focus on initial press and repeat',
        (tester) async {
      await mount(tester);
      final playerFocus = FocusManager.instance.primaryFocus;
      expect(playerFocus?.debugLabel, 'Desktop player');
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      expect(session.seeks.length + session.volumeChanges.length, 1);
      expect(FocusManager.instance.primaryFocus, same(playerFocus));
      await tester.sendKeyRepeatEvent(key);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(playerFocus));
      await tester.sendKeyUpEvent(key);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(session.toggles, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('clicking the player restores focus from the content navigator',
      (tester) async {
    await mount(tester);
    final navigator = tester.state<NavigatorState>(find.descendant(
      of: find.byType(PlayContentNavigator),
      matching: find.byType(Navigator),
    ));
    navigator.focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(session.toggles, 0);
    await tester.tap(find.byType(DesktopGestureDetector));
    await _frames(tester);
    expect(session.toggles, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(session.toggles, 2);
  });

  testWidgets('real detail back and system back preserve then exit the host',
      (tester) async {
    await mount(tester);
    await details(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await _frames(tester);
    expect(find.byType(AnimeInfoView), findsNothing);
    expect(find.text('Player host'), findsOneWidget);
    await details(tester);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.byType(AnimeInfoView), findsNothing);
    expect(find.text('Player host'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tab switching retains details and disables hidden return handling',
      (tester) async {
    await mount(tester);
    await details(tester);
    final detailState = tester.state(find.byType(AnimeInfoView));
    host.currentState!.tabs.animateTo(1);
    await _frames(tester);
    expect(find.text('Comments content'), findsOneWidget);
    host.currentState!.tabs.animateTo(0);
    await _frames(tester);
    expect(tester.state(find.byType(AnimeInfoView)), same(detailState));
    host.currentState!.tabs.animateTo(1);
    await _frames(tester);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offstage content retains details without intercepting host back',
      (tester) async {
    await mount(tester);
    await details(tester);
    final detailState = tester.state(find.byType(AnimeInfoView));
    host.currentState!.hide(true);
    await _frames(tester);
    host.currentState!.hide(false);
    await _frames(tester);
    expect(tester.state(find.byType(AnimeInfoView)), same(detailState));
    host.currentState!.hide(true);
    await _frames(tester);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'successful current playback closes only details and ignores duplicate commands',
      (tester) async {
    await mount(tester);
    await details(tester);
    final view = tester.widget<AnimeInfoView>(find.byType(AnimeInfoView));
    view.onPlay();
    view.onPlay();
    await _frames(tester);
    expect(actions.calls, 1);
    actions.completion.complete();
    await _frames(tester);
    expect(find.byType(AnimeInfoView), findsNothing);
    expect(find.text('Player host'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending playback can finish after the host is disposed',
      (tester) async {
    await mount(tester);
    await details(tester);
    tester.widget<AnimeInfoView>(find.byType(AnimeInfoView)).onPlay();
    await _frames(tester);
    host.currentState!.tabs.animateTo(1);
    await _frames(tester);
    await tester.binding.handlePopRoute();
    await _frames(tester);
    expect(find.text('Home'), findsOneWidget);
    actions.completion.completeError(StateError('disposed request'));
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
        'old playback ${fail ? 'failure' : 'completion'} cannot close reopened details',
        (tester) async {
      await mount(tester);
      await details(tester);
      // Dispatch the real detail view's playback callback, keeping data loading
      // separate from this navigation/async-lifetime regression.
      tester.widget<AnimeInfoView>(find.byType(AnimeInfoView)).onPlay();
      await _frames(tester);
      expect(actions.calls, 1);
      await tester.binding.handlePopRoute();
      await _frames(tester);
      await details(tester);
      final newState = tester.state(find.byType(AnimeInfoView));
      if (fail) {
        actions.completion.completeError(StateError('old request'));
      } else {
        actions.completion.complete();
      }
      await _frames(tester);
      expect(tester.state(find.byType(AnimeInfoView)), same(newState));
      expect(find.text('Player host'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
