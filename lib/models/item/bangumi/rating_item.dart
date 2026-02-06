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
      : rank = json['rank'],
        count = List<int>.from(json['count']),
        score = json['score'] as num,
        total = json['total'];

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'count': count,
      'score': score,
      'total': total,
    };
  }
}
