class CaptchaItem {
  const CaptchaItem({
    required this.captchaId,
    required this.imageBase64,
  });

  final String captchaId;
  final String imageBase64;

  factory CaptchaItem.fromJson(Map<String, dynamic> json) {
    return CaptchaItem(
      captchaId: json['captchaId'] as String,
      imageBase64: json['imageBase64'] as String,
    );
  }
}
