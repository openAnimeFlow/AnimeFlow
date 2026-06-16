class FlowUserCollectionCounts {
  final int planToWatch;
  final int watched;
  final int watching;
  final int onHold;
  final int abandoned;

  const FlowUserCollectionCounts({
    this.planToWatch = 0,
    this.watched = 0,
    this.watching = 0,
    this.onHold = 0,
    this.abandoned = 0,
  });

  factory FlowUserCollectionCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FlowUserCollectionCounts();
    }
    return FlowUserCollectionCounts(
      planToWatch: json['planToWatch'] as int? ?? 0,
      watched: json['watched'] as int? ?? 0,
      watching: json['watching'] as int? ?? 0,
      onHold: json['onHold'] as int? ?? 0,
      abandoned: json['abandoned'] as int? ?? 0,
    );
  }

  /// Bangumi 收藏 type：1=想看 2=看过 3=在看 4=搁置 5=抛弃
  int countForType(int type) {
    switch (type) {
      case 1:
        return planToWatch;
      case 2:
        return watched;
      case 3:
        return watching;
      case 4:
        return onHold;
      case 5:
        return abandoned;
      default:
        return 0;
    }
  }
}
