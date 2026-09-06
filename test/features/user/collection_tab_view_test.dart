import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_state.dart';
import 'package:anime_flow/features/user/presentation/widgets/collection_tab_view.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Collections extends UserCollections {
  int requests = 0;

  @override
  UserCollectionsState build() => UserCollectionsState(tabs: {
        1: UserCollectionTabState(
          data: UserCollectionsItem(data: [], total: 20),
          hasMore: true,
        ),
      });

  @override
  Future<void> loadMore(int type) async {
    requests++;
    state = state.updateTab(
        type,
        (tab) => requests == 1
            ? tab.copyWith(loadMoreErrorMessage: 'Network error')
            : tab.copyWith(
                data: UserCollectionsItem(data: [], total: 0),
                hasMore: false,
                clearLoadMoreErrorMessage: true,
              ));
  }
}

void main() {
  testWidgets(
      'empty cache can load more, retry, then display a true empty state',
      (tester) async {
    final collections = _Collections();
    await tester.pumpWidget(ProviderScope(
      overrides: [userCollectionsProvider.overrideWith(() => collections)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultTabController(
          length: 1,
          child: Builder(
              builder: (context) => Scaffold(
                    body: NestedScrollView(
                      headerSliverBuilder: (context, _) => [
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                          sliver:
                              const SliverAppBar(title: Text('Collections')),
                        ),
                      ],
                      body: CollectionTabView(
                        tabController: DefaultTabController.of(context),
                        tabs: const ['Plan'],
                        refreshIndicatorKeys: {
                          1: GlobalKey<RefreshIndicatorState>()
                        },
                      ),
                    ),
                  )),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CollectionTabView)));
    expect(find.text(l10n.noData), findsNothing);
    expect(collections.requests, 0);
    await tester.tap(find.text(l10n.viewMore));
    await tester.pumpAndSettle();
    expect(collections.requests, 1);
    expect(find.text(l10n.collectionLoadMoreFailed), findsOneWidget);
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(collections.requests, 2);
    expect(find.text(l10n.noData), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
