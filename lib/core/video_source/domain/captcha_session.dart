/// 一次站点验证码验证会话。
abstract interface class CaptchaSession {
  Stream<String?> get onCaptchaImageUrl;
  Future<void> loadForCaptcha(String url, String captchaXpath,
      {String? inputXpath});
  Future<void> reloadCaptchaImage(String captchaXpath, {String? inputXpath});
  Future<void> submitCaptcha({
    required String captchaCode,
    required String inputXpath,
    required String buttonXpath,
    required String pluginName,
    required void Function() onVerified,
  });
  Future<void> loadForButtonClick({
    required String url,
    required String buttonXpath,
    required String pluginName,
    required void Function() onVerified,
  });
  Future<void> saveAndUnload(String pluginName);
  void dispose();
}
