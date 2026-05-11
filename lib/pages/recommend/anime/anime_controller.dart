import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final animeCalendarProvider =
    AsyncNotifierProvider<AnimeController, Calendar>(AnimeController.new);

class AnimeController extends AsyncNotifier<Calendar> {
  @override
  Future<Calendar> build() async {
    return BgmRequest.calendarService();
  }

  /// 刷新日历数据
  Future<void> refreshCalendarDate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => BgmRequest.calendarService());
  }
}
