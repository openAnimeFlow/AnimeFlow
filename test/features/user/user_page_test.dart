import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/user/presentation/pages/user_page.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _profileRevision = Provider<int>((ref) => 0);

class _UserInfo extends CurrentUserInfo {
  Completer<FlowUsers?>? pending;

  @override
  Future<FlowUsers?> build() async {
    ref.watch(_profileRevision);
    return pending == null ? null : await pending!.future;
  }
}

void main() {
  for (final isRefresh in [true, false]) {
    testWidgets('cached null profile shows spinner while loading ($isRefresh)',
        (tester) async {
      final profile = _UserInfo();
      final container = ProviderContainer(overrides: [
        _profileRevision.overrideWithValue(0),
        isLoggedInProvider.overrideWith((ref) async => true),
        currentUserInfoProvider.overrideWith(() => profile),
      ]);
      addTearDown(container.dispose);
      await container.read(isLoggedInProvider.future);
      await container.read(currentUserInfoProvider.future);
      profile.pending = Completer<FlowUsers?>();
      if (isRefresh) {
        container.invalidate(currentUserInfoProvider);
      } else {
        container.updateOverrides([
          _profileRevision.overrideWithValue(1),
          isLoggedInProvider.overrideWith((ref) async => true),
          currentUserInfoProvider.overrideWith(() => profile),
        ]);
      }
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserPage(),
        ),
      ));
      final l10n = AppLocalizations.of(tester.element(find.byType(UserPage)));
      expect(find.text(l10n.noUserProfile), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(l10n.noUserProfile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
