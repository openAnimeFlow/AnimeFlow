import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
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
Future<CalendarWithTags> calendar(Ref ref, CalendarSeason? season) async {
  final calendar = await FlowApi.calendarService(
    year: season?.year,
    month: season?.month,
  );
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
