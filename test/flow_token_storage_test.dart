import 'dart:convert';

import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('temporary secure storage failure does not delete credentials',
      () async {
    var deletes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'read') throw PlatformException(code: 'unavailable');
      if (call.method == 'delete') deletes++;
      return null;
    });
    await expectLater(FlowTokenStorage.instance.getToken(),
        throwsA(isA<PlatformException>()));
    expect(deletes, 0);
  });

  for (final raw in [
    'broken-json',
    jsonEncode({'accessToken': 123})
  ]) {
    test('malformed stored token is removed: $raw', () async {
      var deletes = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'read') return raw;
        if (call.method == 'delete') deletes++;
        return null;
      });
      expect(await FlowTokenStorage.instance.getToken(), isNull);
      expect(deletes, 1);
    });
  }
}
