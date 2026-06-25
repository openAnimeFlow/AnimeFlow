/// 背景图片条目。
class BackgroundImageItem {
  final int id;
  final String image;
  final String name;

  const BackgroundImageItem({
    required this.id,
    required this.image,
    required this.name,
  });

  factory BackgroundImageItem.fromJson(Map<String, dynamic> json) {
    return BackgroundImageItem(
      id: json['id'] as int,
      image: json['image'] as String,
      name: json['name'] as String,
    );
  }
}
