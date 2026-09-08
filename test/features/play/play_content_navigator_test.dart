import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_content_actions.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/recommendation_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/play_content_navigator.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  late GoRouter router;
  late GlobalKey<_HostState> host;
  late _Actions actions;
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
          playSessionProvider.overrideWithValue(_Session()),
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
