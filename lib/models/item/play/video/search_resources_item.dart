class SearchResourcesItem {
  final String name;
  final String link;

  SearchResourcesItem({
    required this.name,
    required this.link,
  });

  factory SearchResourcesItem.fromJson(Map<String, dynamic> json) {
    return SearchResourcesItem(
      name: json['name'] as String? ?? '',
      link: json['link'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'link': link,
    };
  }

  @override
  String toString() {
    return 'VideoResourcesItem{name: $name, link: $link}';
  }
}
