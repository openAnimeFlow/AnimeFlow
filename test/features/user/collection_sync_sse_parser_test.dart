import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';

void main() {
  test(
      'parses split UTF-8, comments, multiline status and ignores unknown events',
      () async {
    final raw = utf8.encode(': heartbeat\r\n\r\nevent: status\r\nid: 1:2\r\n'
        'data: {"status":"WAITING_CONFLICT",\r\n'
        'data: "taskId":1,"statusVersion":2,"message":"等待选择"}\r\n\r\n'
        'event: other\ndata: {}\n\n');
    final events = await decodeCollectionSyncEvents(
        Stream<Uint8List>.fromIterable(
            raw.map((byte) => Uint8List.fromList([byte])))).toList();
    expect(events.length, 2);
    expect(events.first, isNull);
    expect(events.last?.taskId, 1);
    expect(events.last?.statusVersion, 2);
    expect(events.last?.message, '等待选择');
  });

  test('does not accept incomplete events as a complete snapshot', () async {
    final events = await decodeCollectionSyncEvents(Stream.value(
            utf8.encode('event: status\ndata: {"status":"SUCCESS"}')))
        .toList();
    expect(events, isEmpty);
  });
}
