enum VersionType {
  newVersion('有版本更新'),
  localNewer('本地版本较新'),
  sameVersion('当前为最新版本');

  const VersionType(this.message);

  final String message;
}
