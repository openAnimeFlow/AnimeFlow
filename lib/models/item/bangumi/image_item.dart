class ImageItem {
  final String large;
  final String common;
  final String medium;
  final String small;
  final String grid;

  ImageItem({
    required this.large,
    required this.common,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      large: json['large'] as String,
      common: json['common'] as String,
      medium: json['medium'] as String,
      small: json['small'] as String,
      grid: json['grid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'common': common,
      'medium': medium,
      'small': small,
      'grid': grid,
    };
  }
}