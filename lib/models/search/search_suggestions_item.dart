class SearchSuggestionsItem {
  final List<SearchSuggestion> data;

  SearchSuggestionsItem({
    required this.data,
  });

  factory SearchSuggestionsItem.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    return SearchSuggestionsItem(
      data: raw is List
          ? raw
              .map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class SearchSuggestion {
  final int id;
  final String name;
  final String nameCn;

  SearchSuggestion({
    required this.id,
    required this.name,
    required this.nameCn,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nameCn: json['nameCn'] as String? ?? json['nameCN'] as String? ?? '',
    );
  }

  String get displayName => nameCn.isNotEmpty ? nameCn : name;
}
