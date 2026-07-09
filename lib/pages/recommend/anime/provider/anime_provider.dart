import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/bangumi/hot_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_provider.g.dart';

@riverpod
class AnimeCalendar extends _$AnimeCalendar {
  @override
  Future<Calendar> build() async {
    return FlowRequest.calendarService();
  }

  Future<void> refreshCalendarDate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => FlowRequest.calendarService());
  }
}

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

@riverpod
class AnimeHot extends _$AnimeHot {
  static const int limit = 20;

  @override
  Future<AnimeHotState> build() async {
    return _fetchFirstPage();
  }

  Future<AnimeHotState> _fetchFirstPage() async {
    final hotItem = await FlowRequest.getHotService(limit, 0);
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
          await FlowRequest.getHotService(limit, current.items.length);
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
