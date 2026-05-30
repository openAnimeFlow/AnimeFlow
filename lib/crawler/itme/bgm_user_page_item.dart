class BgmUserStatisticsItem {
  final List<Statistic> statistics;

  BgmUserStatisticsItem({required this.statistics});

  factory BgmUserStatisticsItem.fromJson(Map<String, dynamic> json) {
    return BgmUserStatisticsItem(
      statistics: (json['statistics'] as List)
          .map((e) => Statistic.fromJson(e))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'BgmUserPageItem{statistics: $statistics}';
  }
}

class Statistic {
  final String value;
  final String name;

  Statistic({required this.value, required this.name});

  factory Statistic.fromJson(Map<String, dynamic> json) {
    return Statistic(
      value: json['value'],
      name: json['name'],
    );
  }

  @override
  String toString() {
    return 'Statistic{value: $value, name: $name}';
  }
}
