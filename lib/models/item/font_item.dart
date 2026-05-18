class FontItem {
  final String id;
  final String name;
  final String family;
  final String author;
  final String preview;
  final String font;
  final int size;

  FontItem({
    required this.id,
    required this.name,
    required this.family,
    required this.author,
    required this.preview,
    required this.font,
    required this.size,
  });

  factory FontItem.fromJson(Map<String, dynamic> json) {
    return FontItem(
      id: json['id'],
      name: json['name'],
      family: json['family'],
      author: json['author'],
      preview: json['preview'],
      font: json['font'],
      size: json['size'],
    );
  }
}