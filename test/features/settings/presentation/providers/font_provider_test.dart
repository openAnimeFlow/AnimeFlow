import 'dart:async';

import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/shared/models/font_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('switching CDN cancels the previous font list request', () async {
    final requests = <bool, Completer<List<FontItem>>>{};
    final cancelTokens = <bool, CancelToken>{};
    final container = ProviderContainer(overrides: [
      fontRepoCdnProvider.overrideWith(_TestFontRepoCdn.new),
      fontProvider.overrideWith(() => _TestFont(requests, cancelTokens)),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(fontProvider, (previous, next) {});
    addTearDown(subscription.close);

    expect(container.read(fontProvider).isLoading, isTrue);
    expect(requests.keys, contains(false));

    container.read(fontRepoCdnProvider.notifier).setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(requests.keys, contains(true));
    expect(cancelTokens[false]!.isCancelled, isTrue);
    expect(cancelTokens[true]!.isCancelled, isFalse);

    requests[true]!.complete([_font('cdn')]);
    await container.read(fontProvider.future);
    requests[false]!.complete([_font('direct')]);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(fontProvider).requireValue.single.id, 'cdn');
  });

  test('an old preview cannot unregister the current request', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final tasks = container.read(fontNetworkTasksProvider.notifier);
    final previous = CancelToken();
    final current = CancelToken();

    tasks.register('preview:test', previous);
    tasks.register('preview:test', current);
    expect(previous.isCancelled, isTrue);

    tasks.unregister('preview:test', previous);
    tasks.cancelAll();
    expect(current.isCancelled, isTrue);
  });
}

class _TestFontRepoCdn extends FontRepoCdn {
  @override
  bool build() => false;

  @override
  void setEnabled(bool value) => state = value;
}

class _TestFont extends Font {
  _TestFont(this.requests, this.cancelTokens);

  final Map<bool, Completer<List<FontItem>>> requests;
  final Map<bool, CancelToken> cancelTokens;

  @override
  Future<List<FontItem>> getFontList({
    required bool useCdn,
    CancelToken? cancelToken,
  }) {
    final request = Completer<List<FontItem>>();
    requests[useCdn] = request;
    cancelTokens[useCdn] = cancelToken!;
    return request.future;
  }
}

FontItem _font(String id) => FontItem(
      id: id,
      name: id,
      family: id,
      author: 'test',
      preview: '',
      font: '',
      size: 0,
    );
