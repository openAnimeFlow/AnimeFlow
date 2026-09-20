import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/shared/models/flow/collection_conflict_item.dart';

final collectionSyncRepositoryProvider =
    Provider((ref) => CollectionSyncRepository());

class CollectionSyncRepository {
  CollectionSyncRepository(
      {Future<ResponseBody> Function(CancelToken)? openEvents})
      : _openEvents = openEvents ?? FlowApi.openCollectionSyncEvents;

  final Future<ResponseBody> Function(CancelToken) _openEvents;

  /// Null events are heartbeat comments, used only to reset the liveness timer.
  Stream<BgmCollectionSyncStatusItem?> events(CancelToken cancelToken) async* {
    try {
      final response = await _openEvents(cancelToken);
      yield* decodeCollectionSyncEvents(response.stream);
    } finally {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('collection stream closed');
      }
    }
  }

  Future<BgmCollectionSyncStatusItem> status() =>
      FlowApi.getBgmCollectionSyncStatusService();
  Future<BgmCollectionSyncStatusItem> trigger(
          int subjectType, String requestId) =>
      FlowApi.triggerBgmCollectionSyncService(
          subjectType: subjectType, requestId: requestId);
  Future<List<CollectionConflictItem>> conflicts(
          int taskId, int offset, int limit) =>
      FlowApi.getCollectionConflictsService(
          taskId: taskId, offset: offset, limit: limit);
  Future<BgmCollectionSyncStatusItem> resolve(
          int taskId, List<Map<String, dynamic>> items) =>
      FlowApi.resolveCollectionConflictsService(taskId: taskId, items: items);
}

/// Incremental UTF-8 and SSE framing, including split chunks and multiline data.
Stream<BgmCollectionSyncStatusItem?> decodeCollectionSyncEvents(
    Stream<List<int>> bytes) {
  var event = '';
  final data = <String>[];
  var size = 0;
  // Cast the stream itself: Dio emits Uint8List, whose runtime transform type
  // otherwise rejects Utf8Decoder's List<int> input. A transformer chain also
  // propagates cancellation immediately while the socket is idle.
  return bytes
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .transform(
          StreamTransformer<String, BgmCollectionSyncStatusItem?>.fromHandlers(
    handleData: (line, sink) {
      if (line.isEmpty) {
        if (data.isNotEmpty && (event.isEmpty || event == 'status')) {
          final payload = jsonDecode(data.join('\n'));
          if (payload is! Map<String, dynamic>) {
            throw const FormatException('Invalid SSE status');
          }
          sink.add(BgmCollectionSyncStatusItem.fromJson(payload));
        }
        data.clear();
        event = '';
        size = 0;
      } else if (line.startsWith(':')) {
        sink.add(null);
      } else {
        size += line.length;
        if (size > 64 * 1024) {
          throw const FormatException('SSE event too large');
        }
        final colon = line.indexOf(':');
        final field = colon < 0 ? line : line.substring(0, colon);
        var value = colon < 0 ? '' : line.substring(colon + 1);
        if (value.startsWith(' ')) value = value.substring(1);
        if (field == 'event') event = value;
        if (field == 'data') data.add(value);
      }
    },
  ));
}
