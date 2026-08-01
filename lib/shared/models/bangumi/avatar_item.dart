class AvatarItem {
  final String small;
  final String medium;
  final String large;

  AvatarItem({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory AvatarItem.fromJson(Map<String, dynamic> json) {
    return AvatarItem(
      small: json['small'] as String,
      medium: json['medium'] as String,
      large: json['large'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'small': small,
      'medium': medium,
      'large': large,
    };
  }
}