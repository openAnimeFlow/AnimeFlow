import 'dart:async';
import 'dart:io';

import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new episode rejects an older pending conversion', () async {
    final file = await _danmakuFile();
    final converter = _Converter();
    final store = _Store();
    final session = _session(store, converter);
    addTearDown(session.dispose);

    session.beginPlaybackChange();
    session.clear();
    final first = _load(session, file.path);
    await converter.started.future;
    expect(
        store.statuses,
        containsAllInOrder([
          DanmakuLoadStatus.waitingForVideo,
          DanmakuLoadStatus.loading,
        ]));

    session.beginPlaybackChange();
    session.clear();
    await _load(session, file.path);
    expect(converter.calls, 2);
    expect(store.installs, 1);
    expect(store.value.loadStatus, DanmakuLoadStatus.idle);
    final statusCount = store.statuses.length;

    converter.gate.complete();
    await first;
    expect(store.installs, 1);
    expect(store.statuses.length, statusCount);
  });

  test('stopping during conversion discards the pending result', () async {
    final file = await _danmakuFile();
    final converter = _Converter();
    final store = _Store();
    final session = _session(store, converter);
    addTearDown(session.dispose);

    session.beginPlaybackChange();
    session.clear();
    final loading = _load(session, file.path);
    await converter.started.future;
    session.beginPlaybackChange();
    session.clear();
    final statusCount = store.statuses.length;

    converter.gate.complete();
    await loading;
    expect(store.installs, 0);
    expect(store.value.loadStatus, DanmakuLoadStatus.waitingForVideo);
    expect(store.statuses.length, statusCount);
  });
}

Future<File> _danmakuFile() async {
  final directory =
      await Directory.systemTemp.createTemp('danmaku_session_test');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}/danmaku.json');
  await file.writeAsString('[{"m":"test","p":"1,1,16777215,test"}]');
  return file;
}

DanmakuSession _session(_Store store, _Converter converter) => DanmakuSession(
      store: store,
      converter: converter,
      initialChineseMode: DanmakuChineseMode.none,
      readPlayback: () => const DanmakuPlaybackSnapshot(
        position: Duration.zero,
        duration: Duration.zero,
        playing: false,
      ),
      currentUserId: () => null,
    );

Future<void> _load(DanmakuSession session, String path) => session.loadEpisode(
      subjectId: 1,
      episode: 1,
      isLocalPlayback: true,
      localPath: path,
      expectedRequestId: session.requestId,
      isPlaybackCurrent: () => true,
    );

class _Converter extends DanmakuChineseConverter {
  final started = Completer<void>();
  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<List<Danmaku>> convertDanmakus(
      List<Danmaku> items, DanmakuChineseMode mode) async {
    if (++calls == 1) {
      started.complete();
      await gate.future;
    }
    return items;
  }
}

class _Store implements DanmakuStore {
  DanmakuState _state = const DanmakuState();
  final statuses = <DanmakuLoadStatus>[];
  int installs = 0;

  @override
  DanmakuState get value => _state;

  @override
  void setLoadStatus(DanmakuLoadStatus value) {
    statuses.add(value);
    _state = _state.copyWith(loadStatus: value);
  }

  @override
  void setDanmakus(Map<int, List<Danmaku>> value) {
    installs++;
    _state = _state.copyWith(danmakus: value);
  }

  @override
  void clearDanmakus() => _state = _state.copyWith(danmakus: const {});

  @override
  void incrementEpoch() => _state = _state.copyWith(epoch: _state.epoch + 1);

  @override
  void setHiddenPlatforms(Set<String> value) =>
      _state = _state.copyWith(hiddenPlatforms: value);

  @override
  void toggleEnabled() => _state = _state.copyWith(enabled: !_state.enabled);

  @override
  void toggleHiddenPlatform(String platform) {
    final next = {..._state.hiddenPlatforms};
    if (!next.remove(platform)) next.add(platform);
    _state = _state.copyWith(hiddenPlatforms: next);
  }
}
