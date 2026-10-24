import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/character_info/presentation/providers/character_info_args_provider.dart';
import 'package:anime_flow/features/characters/presentation/providers/characters_args_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_args_provider.dart';
import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([animeInfoArgs, playExtra, characterInfoArgs, charactersArgs])
void main() {
  Future<void> probe(WidgetTester tester, List<GoRouteData> routes,
      void Function(int, WidgetRef) inspect) async {
    final router = GoRouter(initialLocation: '/probe', routes: [
      GoRoute(
          path: '/probe',
          builder: (context, state) => Column(children: [
                for (var i = 0; i < routes.length; i++)
                  Builder(builder: (context) {
                    // 保留实际路由的 Provider 覆盖配置，用参数探针组件替换
                    // 依赖原生播放器和大量网络请求的页面子组件。
                    final scope =
                        routes[i].build(context, state) as ProviderScope;
                    return ProviderScope(
                      overrides: scope.overrides,
                      child: Consumer(builder: (context, ref, child) {
                        inspect(i, ref);
                        return const SizedBox();
                      }),
                    );
                  }),
              ])),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'play route reconstructs inputs without extra and isolates sessions',
      (tester) async {
    final sessions = <int, PlayRouteExtra>{};
    await probe(tester, [
      const PlayRoute(
          id: 1, name: 'First', image: 'first', continueEpisodeId: 11),
      const PlayRoute(id: 2, name: 'Second', image: 'second'),
    ], (index, ref) {
      final session = ref.watch(playExtraProvider);
      sessions[index] = session;
      final info = ref.watch(animeInfoArgsProvider);
      expect(info.id, session.playExtra.subjectId);
      expect(info.name, session.playExtra.subjectName);
      expect(info.image, session.playExtra.subjectCover);
      expect(ref.read(animeInfoInitialProvider), isNull);
    });
    expect(sessions[0]!.playExtra.subjectId, 1);
    expect(sessions[1]!.playExtra.subjectId, 2);
    expect(sessions[0]!.continueEpisodeId, 11);
    expect(sessions[1]!.continueEpisodeId, isNull);
    expect(sessions.values.every((s) => !s.isOfflineMode), isTrue);
  });

  testWidgets(
      'play route retains offline input and seeds matching anime inputs',
      (tester) async {
    const args = PlayRouteExtra(
      playExtra: PlayExtra(
          subjectId: 5,
          subjectName: 'Offline',
          subjectCover: 'cover',
          subjectAliases: ['alias']),
      isOfflineMode: true,
      offlineMediaPath: '/local/video.mkv',
      offlineDanmakuPath: '/local/video.xml',
      continueEpisodeId: 6,
    );
    await probe(tester, [PlayRoute.fromExtra(args)], (_, ref) {
      expect(ref.watch(playExtraProvider), same(args));
      expect(ref.watch(animeInfoArgsProvider).id, 5);
    });
  });

  testWidgets(
      'anime and character routes retain URL fallbacks and display names',
      (tester) async {
    await probe(tester, [
      const AnimeInfoRoute(id: 9, name: 'Anime', image: 'cover'),
      const CharacterInfoRoute(
          id: 3,
          name: '译名',
          image: 'image',
          $extra: CharacterInfoExtra(
              characterId: 3,
              characterName: 'Original',
              characterImage: 'image')),
      const CharactersRoute(subjectsId: 9),
    ], (index, ref) {
      switch (index) {
        case 0:
          expect(ref.watch(animeInfoArgsProvider).id, 9);
          expect(ref.watch(animeInfoArgsProvider).name, 'Anime');
        case 1:
          expect(ref.watch(characterInfoArgsProvider).characterName, '译名');
          expect(ref.watch(characterInfoArgsProvider).characterId, 3);
        case 2:
          expect(ref.watch(charactersArgsProvider), 9);
      }
    });
  });
}
