import 'dart:async';

import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_provider.g.dart';

typedef CalendarSeason = ({int year, int month});

class CalendarWithTags {
  const CalendarWithTags({required this.calendar, required this.tags});

  final Calendar calendar;
  final List<String> tags;
}

/// A null season requests the current season, shared by the home and calendar pages.
@riverpod
Stream<CalendarWithTags> calendar(Ref ref, CalendarSeason? season) async* {
  final token = CancelToken();
  ref.onDispose(() => token.cancel());
  final now = DateTime.now();
  // 当前放送表含最新/下一集信息，跨天后不能继续命中昨天的缓存。
  final key = season == null
      ? 'current:${now.year}:${now.month}:${now.day}'
      : 'season:${season.year}:${season.month}';
  if (season == null) {
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timer = Timer(midnight.difference(now), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  final forceRefresh = !ref.isFirstBuild;
  final cached = JsonResponseCache.read(
    Storage.calendarCache,
    key,
    fromJson: Calendar.fromJson,
  );
  if (cached != null) {
    yield _withTags(cached.data);
    if (!forceRefresh && cached.isFresh) return;
  }
  if (token.isCancelled) return;
  try {
    final result = await JsonResponseCache.get(
      Storage.calendarCache,
      key,
      load: () => FlowApi.calendarService(
          year: season?.year, month: season?.month, cancelToken: token),
      fromJson: Calendar.fromJson,
      toJson: (calendar) => calendar.toJson(),
      cancelToken: token,
      forceRefresh: true,
      fallbackToCache: false,
    );
    if (!token.isCancelled) yield _withTags(result);
  } catch (error) {
    if (token.isCancelled) return;
    if (cached == null) rethrow;
    debugPrint('Failed to refresh calendar cache: $error');
  }
}

CalendarWithTags _withTags(Calendar calendar) {
  final tags = calendar.calendarData.values
      .expand((items) => items)
      .expand((item) => item.subject.metaTags)
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  return CalendarWithTags(calendar: calendar, tags: List.unmodifiable(tags));
}
