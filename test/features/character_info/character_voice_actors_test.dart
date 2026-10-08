import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/character_info_extra.dart';
import 'package:anime_flow/features/character_info/presentation/providers/character_info_provider.dart';
import 'package:anime_flow/features/character_info/presentation/widgets/character_voice_actors.dart';
import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_detail_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_subjects_item.dart';
import 'package:anime_flow/shared/models/bangumi/image_four_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _LoadingDetail extends CharacterInfoDetail {
  @override
  Future<CharacterDetailItem> build() =>
      Completer<CharacterDetailItem>().future;
}

class _LoadingWorks extends CharacterWorks {
  @override
  Future<CharacterCastsItem> build() => Completer<CharacterCastsItem>().future;
}

class _LoadingComments extends CharacterComments {
  @override
  Future<List<CharacterCommentItem>> build() =>
      Completer<List<CharacterCommentItem>>().future;
}

CharacterCast cast(int id) => CharacterCast(
      person: Actor(
        id: id,
        name: 'Original name $id',
        nameCN: id == 2 ? '' : '声优 $id',
        type: 1,
        info: '性别 女 / 生日 1995年4月8日 / 血型 AB型 / 身高 160cm，完整资料 $id',
        career: ['seiyu', 'actor', 'artist'],
        comment: 60,
        lock: false,
        nsfw: false,
        images: ImageFourItem(large: '', medium: '', small: '', grid: ''),
      ),
      relation: 1,
      summary: '配音说明 $id',
    );

void main() {
  for (final width in [320.0, 1100.0]) {
    testWidgets('shows every voice actor and full profile at width $width',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final casts = List.generate(4, cast);

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CharacterVoiceActorsView(casts: casts),
            ),
          ),
        ),
      ));
      await tester.pump();

      for (var id = 0; id < casts.length; id++) {
        expect(find.text('Original name $id'), findsOneWidget);
        expect(find.text(casts[id].person.info), findsOneWidget);
        expect(find.text('配音说明 $id'), findsOneWidget);
      }
      expect(find.text('声优 2'), findsNothing);
      expect(find.textContaining('声优 / 演员 / 艺人'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows an empty state when no casts are available',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: CharacterVoiceActorsView(casts: [])),
    ));
    await tester.pump();
    expect(find.text('No voice actor information available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'typed character route passes complete casts into the detail page',
      (tester) async {
    final route = CharacterInfoRoute.fromExtra(CharacterInfoExtra(
      characterId: 133203,
      characterName: '水之江梅',
      characterImage: '',
      casts: [cast(0), cast(1), cast(2)],
    ));
    final router = GoRouter(
      routes: [$characterInfoRoute],
      initialLocation: route.location,
      initialExtra: route.$extra,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        characterInfoDetailProvider.overrideWith(_LoadingDetail.new),
        characterWorksProvider.overrideWith(_LoadingWorks.new),
        characterCommentsProvider.overrideWith(_LoadingComments.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    expect(find.byType(CharacterVoiceActorsView), findsOneWidget);
    final view = tester.widget<CharacterVoiceActorsView>(
      find.byType(CharacterVoiceActorsView),
    );
    expect(view.casts, hasLength(3));
    expect(view.casts.first.person.info, cast(0).person.info);
    expect(view.casts.first.relation, 1);
    expect(view.casts.first.summary, '配音说明 0');
    expect(tester.takeException(), isNull);
  });
}
