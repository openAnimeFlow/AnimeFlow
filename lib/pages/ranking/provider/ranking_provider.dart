import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ranking_provider.g.dart';

class RankingState {
  const RankingState({
    this.items = const [],
    this.hasMore = true,
    this.currentPage = 0,
    this.selectedSort = SortType.rank,
    this.selectedYear,
    this.selectedMonth,
    this.isReloading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<Subject> items;
  final bool hasMore;
  final int currentPage;
  final SortType selectedSort;
  final int? selectedYear;
  final int? selectedMonth;

  /// 切换筛选或下拉刷新
  final bool isReloading;

  /// 滚动加载下一页
  final bool isLoadingMore;

  /// 刷新或切换筛选失败时的提示
  final String? errorMessage;

  RankingState copyWith({
    List<Subject>? items,
    bool? hasMore,
    int? currentPage,
    SortType? selectedSort,
    int? selectedYear,
    int? selectedMonth,
    bool? isReloading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearYear = false,
    bool clearMonth = false,
    bool clearError = false,
  }) {
    return RankingState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedSort: selectedSort ?? this.selectedSort,
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      selectedMonth: clearMonth ? null : (selectedMonth ?? this.selectedMonth),
      isReloading: isReloading ?? this.isReloading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
List<int> rankingYears(Ref ref) {
  final currentYear = DateTime.now().year;
  return List.generate(20, (index) => currentYear - index);
}

@riverpod
List<int> rankingMonths(Ref ref) {
  return List.generate(12, (index) => index + 1);
}

@Riverpod(keepAlive: true)
class Ranking extends _$Ranking {
  @override
  Future<RankingState> build() async {
    return _fetchFirstPage();
  }

  Future<RankingState> _fetchFirstPage({
    SortType? sort,
    int? year,
    int? month,
    bool clearYear = false,
    bool clearMonth = false,
  }) async {
    final current = state.asData?.value;
    final effectiveSort = sort ?? current?.selectedSort ?? SortType.rank;
    final effectiveYear = clearYear ? null : (year ?? current?.selectedYear);
    final effectiveMonth =
        clearMonth ? null : (month ?? current?.selectedMonth);

    final response = await FlowRequest.rankService(
      page: 1,
      sort: effectiveSort,
      year: effectiveYear,
      month: effectiveMonth,
    );

    return RankingState(
      items: response.data,
      currentPage: 1,
      hasMore: response.data.isNotEmpty,
      selectedSort: effectiveSort,
      selectedYear: effectiveYear,
      selectedMonth: effectiveMonth,
    );
  }

  Future<void> refresh() async {
    await _reloadWithFilters();
  }

  Future<void> setSort(SortType sort) async {
    await _reloadWithFilters(sort: sort);
  }

  Future<void> setYear(int? year) async {
    if (year == null) {
      await _reloadWithFilters(clearYear: true);
    } else {
      await _reloadWithFilters(year: year);
    }
  }

  Future<void> setMonth(int? month) async {
    if (month == null) {
      await _reloadWithFilters(clearMonth: true);
    } else {
      await _reloadWithFilters(month: month);
    }
  }

  Future<void> _reloadWithFilters({
    SortType? sort,
    int? year,
    int? month,
    bool clearYear = false,
    bool clearMonth = false,
  }) async {
    final current = state.asData?.value;
    final effectiveSort = sort ?? current?.selectedSort ?? SortType.rank;
    final effectiveYear = clearYear ? null : (year ?? current?.selectedYear);
    final effectiveMonth =
        clearMonth ? null : (month ?? current?.selectedMonth);

    if (current == null) {
      state = await AsyncValue.guard(
        () => _fetchFirstPage(
          sort: effectiveSort,
          year: effectiveYear,
          month: effectiveMonth,
          clearYear: clearYear,
          clearMonth: clearMonth,
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        selectedSort: effectiveSort,
        selectedYear: effectiveYear,
        selectedMonth: effectiveMonth,
        isReloading: true,
        clearError: true,
        clearYear: clearYear,
        clearMonth: clearMonth,
      ),
    );

    try {
      final next = await _fetchFirstPage(
        sort: effectiveSort,
        year: effectiveYear,
        month: effectiveMonth,
        clearYear: clearYear,
        clearMonth: clearMonth,
      );
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          errorMessage: _formatError(error),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isReloading ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = current.currentPage + 1;
      final response = await FlowRequest.rankService(
        page: page,
        sort: current.selectedSort,
        year: current.selectedYear,
        month: current.selectedMonth,
      );

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...response.data],
          currentPage: page,
          hasMore: response.data.isNotEmpty,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          errorMessage: '加载更多失败，请稍后重试',
        ),
      );
    }
  }

  String _formatError(Object error) {
    final message = error.toString();
    const prefix = 'Exception: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }
}
