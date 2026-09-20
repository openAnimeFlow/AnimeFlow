import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/widgets/account/collection_conflicts_dialog.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/shared/models/flow/collection_conflict_item.dart';
import 'bgm_collection_sync_provider_test.dart' show Token;

class Sync extends BgmCollectionSync {
  @override
  Future<BgmCollectionSyncStatusItem?> build() async => null;
  @override
  Future<void> refreshStatus() async {}
}

class Repo extends CollectionSyncRepository {
  final offsets = <int>[];
  List<Map<String, dynamic>> submitted = [];
  List<CollectionConflictItem> rows = List.generate(21, (i) => item(i, 1));
  bool partialFailure = false;
  bool bound = true;
  static CollectionConflictItem item(int id, int version) =>
      CollectionConflictItem(
          conflictId: id,
          subjectId: id,
          subjectName: 'Subject $id',
          subjectImage: 'https://example.com/cover.jpg',
          localType: 3,
          remoteType: 2,
          conflictVersion: version);
  @override
  Future<List<CollectionConflictItem>> conflicts(
      int taskId, int offset, int limit) async {
    offsets.add(offset);
    return rows.skip(offset).take(limit).toList();
  }

  @override
  Future<BgmCollectionSyncStatusItem> resolve(
      int taskId, List<Map<String, dynamic>> items) async {
    submitted = items;
    if (partialFailure) {
      rows = rows.skip(1).map((e) => item(e.conflictId, 2)).toList();
      throw StateError('STALE_CONFLICT');
    }
    final ids = items.map((e) => e['conflictId']).toSet();
    rows.removeWhere((e) => ids.contains(e.conflictId));
    return const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.running);
  }
}

void main() {
  Future<ProviderContainer> mount(WidgetTester tester, Repo repo) async {
    final c = ProviderContainer(overrides: [
      currentFlowTokenProvider.overrideWith(Token.new),
      bangumiBindProvider.overrideWith(
          (ref) async => BangumiBindItem(bound: repo.bound, platformUid: 1)),
      bgmCollectionSyncProvider.overrideWith(Sync.new),
      collectionSyncRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    await c.read(currentFlowTokenProvider.future);
    await c.read(bangumiBindProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CollectionConflictsDialog(taskId: 1)),
        )));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('unbinding disables old dialog decisions', (tester) async {
    final repo = Repo();
    final c = await mount(tester, repo);
    await tester
        .tap(find.byKey(const ValueKey('collection-conflicts-use-animeflow')));
    await tester.pumpAndSettle();
    repo.bound = false;
    c.invalidate(bangumiBindProvider);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Your account or Bangumi binding changed. Close and reopen this window.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(repo.submitted, isEmpty);
  });

  testWidgets('conflict controls fit a narrow screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, Repo());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'loads beyond 20 and submits all explicitly selected loaded items',
      (tester) async {
    final repo = Repo();
    await mount(tester, repo);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('collection-conflicts-load-more')), 300,
        scrollable: find.byType(Scrollable).last, maxScrolls: 40);
    await tester
        .tap(find.byKey(const ValueKey('collection-conflicts-load-more')));
    await tester.pumpAndSettle();
    expect(repo.offsets, [0, 20]);
    await tester
        .tap(find.byKey(const ValueKey('collection-conflicts-use-animeflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-conflicts-submit')));
    await tester.pumpAndSettle();
    expect(repo.submitted.length, 21);
    expect(repo.submitted.every((e) => e['selectedType'] == 3), isTrue);
    expect(repo.offsets.last, 0);
    expect(find.text('No conflicts awaiting a choice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a single choice can be submitted without selecting the whole page',
      (tester) async {
    final repo = Repo();
    await mount(tester, repo);
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('conflict-0-bangumi')), findsOneWidget);
    expect(find.byKey(const ValueKey('conflict-0-animeflow')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('conflict-0-bangumi')));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
    final highlight = find.byKey(const ValueKey('conflict-0-highlight'));
    final left = tester.getTopLeft(highlight).dx;
    await tester.tap(find.byKey(const ValueKey('conflict-0-animeflow')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final middle = tester.getTopLeft(highlight).dx;
    await tester.pumpAndSettle();
    final right = tester.getTopLeft(highlight).dx;
    expect(middle, greaterThan(left));
    expect(middle, lessThan(right));
    await tester.tap(find.byKey(const ValueKey('collection-conflicts-submit')));
    await tester.pumpAndSettle();
    expect(repo.submitted.single['conflictId'], 0);
    expect(repo.submitted.single['selectedType'], 3);
    expect(repo.rows.length, 20);
  });

  testWidgets('partial acceptance reloads offset zero and clears stale choices',
      (tester) async {
    final repo = Repo()..partialFailure = true;
    await mount(tester, repo);
    await tester
        .tap(find.byKey(const ValueKey('collection-conflicts-use-bangumi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-conflicts-submit')));
    await tester.pumpAndSettle();
    expect(repo.offsets, [0, 0]);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('collection-conflicts-submit')))
            .onPressed,
        isNull);
    expect(repo.rows.first.conflictVersion, 2);
    expect(find.textContaining('Some choices may have been received'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
