class RatingItem {
  final int rank;
  final List<int> count;
  final num score;
  final int total;

  RatingItem({
    required this.rank,
    required this.count,
    required this.score,
    required this.total,
  });

  RatingItem.fromJson(Map<String, dynamic> json)
      : rank = json['rank'] ?? 0,
        count = json['count'] != null
            ? List<int>.from(json['count'])
            : List<int>.filled(10, 0),
        score = json['score'] as num? ?? 0,
        total = json['total'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'count': count,
      'score': score,
      'total': total,
    };
  }
}
