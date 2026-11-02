enum UpdateDownloadRoute { ghProxy, github }

class DownloadInfo {
  final String url;
  final String fileName;
  final int size;
  final String htmlUrl;
  final UpdateDownloadRoute route;

  DownloadInfo(this.url, this.fileName, this.size, this.htmlUrl,
      {this.route = UpdateDownloadRoute.github});

  DownloadInfo withRoute(UpdateDownloadRoute route) =>
      DownloadInfo(url, fileName, size, htmlUrl, route: route);

  factory DownloadInfo.fromJson(Map<String, dynamic> json, String htmlUrl) {
    return DownloadInfo(
      json['browser_download_url'] as String,
      json['name'] as String,
      json['size'] as int,
      htmlUrl,
    );
  }
}
