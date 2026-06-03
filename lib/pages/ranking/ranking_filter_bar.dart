import 'package:anime_flow/models/enums/sort_type.dart';
import 'package:anime_flow/pages/ranking/provider/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingFilterBar extends ConsumerWidget {
  const RankingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingProvider).asData?.value;
    final years = ref.watch(rankingYearsProvider);
    final months = ref.watch(rankingMonthsProvider);
    final notifier = ref.read(rankingProvider.notifier);
    final selectedSort = rankingState?.selectedSort ?? SortType.rank;
    final selectedYear = rankingState?.selectedYear;
    final selectedMonth = rankingState?.selectedMonth;

    return Center(
      child: Wrap(
        spacing: 5,
        children: [
          PopupMenuButton<SortType>(
            offset: const Offset(0, 40),
            initialValue: selectedSort,
            itemBuilder: (context) {
              return SortType.values.map((type) {
                return PopupMenuItem<SortType>(
                  value: type,
                  child: Text(type.name),
                );
              }).toList();
            },
            onSelected: notifier.setSort,
            child: _FilterChip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    selectedSort.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<int>(
            offset: const Offset(0, 40),
            initialValue: selectedYear ?? -1,
            child: _FilterChip(
              child: Text(
                selectedYear == null ? '全部年份' : '$selectedYear年',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: -1,
                  child: Text('全部'),
                ),
                ...years.map((year) {
                  return PopupMenuItem<int>(
                    value: year,
                    child: Text('$year年'),
                  );
                }),
              ];
            },
            onSelected: (value) {
              notifier.setYear(value == -1 ? null : value);
            },
          ),
          PopupMenuButton<int>(
            offset: const Offset(0, 40),
            initialValue: selectedMonth ?? -1,
            child: _FilterChip(
              child: Text(
                selectedMonth == null ? '全部月份' : '$selectedMonth月',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(
                  value: -1,
                  child: Text('全部'),
                ),
                ...months.map((month) {
                  return PopupMenuItem<int>(
                    value: month,
                    child: Text('$month月'),
                  );
                }),
              ];
            },
            onSelected: (value) {
              notifier.setMonth(value == -1 ? null : value);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: child,
    );
  }
}
