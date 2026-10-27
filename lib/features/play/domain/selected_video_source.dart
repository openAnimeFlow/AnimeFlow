/// 一个已选中的站点播放页，供自动选源和单集手动绑定共同使用。
class SelectedVideoSource {
  const SelectedVideoSource({
    required this.websiteName,
    required this.websiteIcon,
    required this.resourceTitle,
    required this.lineName,
    required this.videoUrl,
  });

  final String websiteName;
  final String websiteIcon;
  final String resourceTitle;
  final String lineName;
  final String videoUrl;
}
