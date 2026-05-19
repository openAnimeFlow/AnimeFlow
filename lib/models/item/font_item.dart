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
      id: json['id'] as String,
      name: json['name'] as String,
      family: json['family'] as String,
      author: json['author'] as String,
      preview: json['preview'] as String,
      font: json['font'] as String,
      size: (json['size'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'family': family,
        'author': author,
        'preview': preview,
        'font': font,
        'size': size,
      };
}