class ImageFourItem {
  final String large;
  final String medium;
  final String small;
  final String grid;

  ImageFourItem({
    required this.large,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory ImageFourItem.fromJson(Map<String, dynamic> json) {
    return ImageFourItem(
      large: json['large'] as String,
      medium: json['medium'] as String,
      small: json['small'] as String,
      grid: json['grid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'large': large,
      'medium': medium,
      'small': small,
      'grid': grid,
    };
  }
}