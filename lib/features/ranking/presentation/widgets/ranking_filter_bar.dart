import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RankingFilterBar extends ConsumerWidget {
  const RankingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                  child: Text(_sortLabel(type, l10n)),
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
                    _sortLabel(selectedSort, l10n),
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
                selectedYear == null
                    ? l10n.allYears
                    : l10n.yearSuffix(selectedYear),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem<int>(
                  value: -1,
                  child: Text(l10n.all),
                ),
                ...years.map((year) {
                  return PopupMenuItem<int>(
                    value: year,
                    child: Text(l10n.yearSuffix(year)),
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
                selectedMonth == null
                    ? l10n.allMonths
                    : l10n.monthSuffix(selectedMonth),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem<int>(
                  value: -1,
                  child: Text(l10n.all),
                ),
                ...months.map((month) {
                  return PopupMenuItem<int>(
                    value: month,
                    child: Text(l10n.monthSuffix(month)),
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

  String _sortLabel(SortType type, AppLocalizations l10n) {
    return switch (type) {
      SortType.rank => l10n.sortRank,
      SortType.trends => l10n.sortTrends,
      SortType.collects => l10n.sortCollects,
      SortType.date => l10n.sortDate,
      SortType.title => l10n.sortTitle,
    };
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
