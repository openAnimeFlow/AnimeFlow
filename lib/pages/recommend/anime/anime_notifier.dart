import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final animeCalendarProvider =
    AsyncNotifierProvider<AnimeCalendarNotifier, Calendar>(
  AnimeCalendarNotifier.new,
);

class AnimeCalendarNotifier extends AsyncNotifier<Calendar> {
  @override
  Future<Calendar> build() async {
    return BgmRequest.calendarService();
  }

  Future<void> refreshCalendarDate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => BgmRequest.calendarService());
  }
}

final animeHotProvider = AsyncNotifierProvider<AnimeHotNotifier, AnimeHotState>(
  AnimeHotNotifier.new,
);

class AnimeHotState {
  const AnimeHotState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<Data> items;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  AnimeHotState copyWith({
    List<Data>? items,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AnimeHotState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AnimeHotNotifier extends AsyncNotifier<AnimeHotState> {
  static const int limit = 20;

  @override
  Future<AnimeHotState> build() async {
    return _fetchFirstPage();
  }

  Future<AnimeHotState> _fetchFirstPage() async {
    final hotItem = await BgmRequest.getHotService(limit, 0);
    return AnimeHotState(
      items: hotItem.data,
      hasMore: hotItem.data.length >= limit,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoading: true, clearErrorMessage: true),
    );

    try {
      final hotItem =
          await BgmRequest.getHotService(limit, current.items.length);
      final nextItems = [...current.items, ...hotItem.data];
      state = AsyncData(
        AnimeHotState(
          items: nextItems,
          hasMore: hotItem.data.length >= limit,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }
}
