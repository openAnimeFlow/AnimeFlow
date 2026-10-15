import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_probe.dart';
import 'package:flutter/services.dart';
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
  int reads = 0;
  int writes = 0;
  int activeWrites = 0;
  int maxActiveWrites = 0;
  Completer<void>? writeGate;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    expect(key, StorageKey.flowEndpointPool);
    reads++;
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
    reads = writes = activeWrites = maxActiveWrites = 0;
    writeGate = null;
  }
}

class TextAssetBundle extends CachingAssetBundle {
  TextAssetBundle(this.text);
  final String? text;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    expect(key, FlowEndpointPool.assetPath);
    reads++;
    if (text == null) throw StateError('asset missing');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text!)));
  }
}

const ipA = '104.19.52.165';
const ipB = '172.66.214.245';
const ipC = '162.159.82.236';

class FixedProbe implements FlowProbeSession {
  FixedProbe(this.values);
  final Map<String?, Duration?> values;
  int active = 0;
  int maxActive = 0;
  final calls = <String?>[];
  final pending = <Completer<Duration?>>[];
  bool hold = false;
  bool cancelled = false;

  @override
  Future<Duration?> probe(String? address) async {
    calls.add(address);
    active++;
    maxActive = max(maxActive, active);
    try {
      if (hold) {
        final completion = Completer<Duration?>();
        pending.add(completion);
        return await completion.future;
      }
      await Future<void>.delayed(Duration.zero);
      return cancelled ? null : values[address];
    } finally {
      active--;
    }
  }

  @override
  void cancel() {
    cancelled = true;
    for (final item in pending) {
      if (!item.isCompleted) item.complete(null);
    }
  }
}
