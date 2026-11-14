/// 已选中的站点、线路及其剧集页面。
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
