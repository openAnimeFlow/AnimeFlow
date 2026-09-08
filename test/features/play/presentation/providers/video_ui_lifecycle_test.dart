import 'dart:async';

import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

class _Brightness extends ScreenBrightnessPlatform {
  Completer<double>? pendingRead;
  int resets = 0;
  bool failReset = false;
  final restoredValues = <double>[];

  @override
  Future<double> get application => pendingRead?.future ?? Future.value(0.7);

  @override
  Future<void> resetApplicationScreenBrightness() async {
    resets++;
    if (failReset) throw StateError('Reset unsupported');
  }

  @override
  Future<void> setApplicationScreenBrightness(double brightness) async {
    restoredValues.add(brightness);
  }
}

const _extra = PlayRouteExtra(
  playExtra: PlayExtra(
    subjectId: 1,
    subjectName: 'Subject',
    subjectCover: '',
    subjectAliases: [],
  ),
);

ProviderContainer _route(ProviderContainer root) => ProviderContainer(
      parent: root,
      overrides: [playExtraProvider.overrideWithValue(_extra)],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const batteryChannel = MethodChannel('dev.fluttercommunity.plus/battery');
  const chargingChannel = MethodChannel('dev.fluttercommunity.plus/charging');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ScreenBrightnessPlatform originalBrightness;
  late _Brightness brightness;
  late int batteryReads;
  late int batteryStateReads;
  late int subscriptions;
  late int cancellations;
  Completer<int>? pendingBattery;

  setUp(() {
    originalBrightness = ScreenBrightnessPlatform.instance;
    brightness = _Brightness();
    ScreenBrightnessPlatform.instance = brightness;
    batteryReads = batteryStateReads = subscriptions = cancellations = 0;
    pendingBattery = null;
    messenger.setMockMethodCallHandler(batteryChannel, (call) async {
      if (call.method == 'getBatteryLevel') {
        batteryReads++;
        return pendingBattery == null ? 80 : await pendingBattery!.future;
      }
      if (call.method == 'getBatteryState') {
        batteryStateReads++;
        return 'discharging';
      }
      return null;
    });
    messenger.setMockMethodCallHandler(chargingChannel, (call) async {
      if (call.method == 'listen') subscriptions++;
      if (call.method == 'cancel') cancellations++;
      return null;
    });
  });

  tearDown(() {
    ScreenBrightnessPlatform.instance = originalBrightness;
    messenger.setMockMethodCallHandler(batteryChannel, null);
    messenger.setMockMethodCallHandler(chargingChannel, null);
  });

  testWidgets('route scopes isolate UI and retain it without listeners',
      (tester) async {
    final root = ProviderContainer();
    final first = _route(root);
    final second = _route(root);
    final firstUi = first.read(videoUiProvider.notifier);
    final secondUi = second.read(videoUiProvider.notifier);
    expect(identical(firstUi, secondUi), isFalse);
    firstUi.hideControlsUi();
    firstUi.startProgressDrag(const Duration(seconds: 12));
    firstUi.hideControlsUi();
    await tester.pump();
    expect(first.read(videoUiProvider).isShowControlsUi, isFalse);
    expect(first.read(videoUiProvider).isHorizontalDragging, isTrue);
    expect(second.read(videoUiProvider).isShowControlsUi, isTrue);
    expect(second.read(videoUiProvider).isHorizontalDragging, isFalse);

    first.dispose();
    await tester.pump();
    final readsBefore = batteryReads;
    await tester.pump(const Duration(seconds: 31));
    expect(batteryReads, readsBefore + 1);
    expect(second.read(videoUiProvider.notifier), same(secondUi));
    second.dispose();
    await tester.pump();
    expect(brightness.resets, 2);
    expect(cancellations, subscriptions);
    final readsAfter = batteryReads;
    await tester.pump(const Duration(seconds: 31));
    expect(batteryReads, readsAfter);
    root.dispose();
  });

  testWidgets('exit during brightness initialization starts no background work',
      (tester) async {
    brightness.pendingRead = Completer<double>();
    final root = ProviderContainer();
    final route = _route(root);
    route.read(videoUiProvider);
    route.dispose();
    expect(brightness.resets, 1);
    brightness.pendingRead!.complete(0.9);
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(batteryReads, 0);
    expect(subscriptions, 0);
    expect(tester.takeException(), isNull);
    root.dispose();
  });

  testWidgets(
      'exit during battery initialization cannot recreate subscriptions',
      (tester) async {
    pendingBattery = Completer<int>();
    final root = ProviderContainer();
    final route = _route(root);
    route.read(videoUiProvider);
    await tester.pump();
    expect(batteryReads, 1);
    route.dispose();
    pendingBattery!.complete(80);
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(batteryStateReads, 0);
    expect(subscriptions, 0);
    expect(batteryReads, 1);
    expect(tester.takeException(), isNull);
    root.dispose();
  });

  testWidgets('brightness fallback restores captured value after disposal',
      (tester) async {
    brightness.failReset = true;
    final root = ProviderContainer();
    final route = _route(root);
    route.read(videoUiProvider);
    await tester.pump();
    route.dispose();
    await tester.pump();
    expect(brightness.restoredValues, [0.7]);
    expect(tester.takeException(), isNull);
    root.dispose();
  });
}
