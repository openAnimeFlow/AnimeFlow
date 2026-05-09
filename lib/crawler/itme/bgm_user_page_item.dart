class BgmUserPageItem {
  final List<Statistic> statistics;

  BgmUserPageItem({required this.statistics});

  factory BgmUserPageItem.fromJson(Map<String, dynamic> json) {
    return BgmUserPageItem(
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
