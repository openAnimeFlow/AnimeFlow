import 'dart:async';

import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

MemorySettingsBox setUpFlowSettings() {
  final settings = MemorySettingsBox();
  setUpAll(() => Storage.setting = settings);
  setUp(settings.reset);
  return settings;
}

class MemorySettingsBox extends Fake implements Box<dynamic> {
  Object? value;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;
  int activeWrites = 0;
  int maxActiveWrites = 0;
  Completer<void>? writeGate;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    expect(key, StorageKey.flowEndpointPool);
    if (failRead) throw StateError('storage unavailable');
    return value ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, dynamic value) async {
    expect(key, StorageKey.flowEndpointPool);
    writes++;
    activeWrites++;
    if (activeWrites > maxActiveWrites) maxActiveWrites = activeWrites;
    try {
      if (failWrite) throw StateError('write unavailable');
      await writeGate?.future;
      this.value = value;
    } finally {
      activeWrites--;
    }
  }

  void reset() {
    value = null;
    failRead = failWrite = false;
    writes = activeWrites = maxActiveWrites = 0;
    writeGate = null;
  }
}

const ipA = '104.19.52.165';
const ipB = '172.66.214.245';
const ipC = '162.159.82.236';
