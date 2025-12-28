enum SortType {
  rank('排名','rank'),
  trends('热门','trends'),
  collects('收藏','collects'),
  date('日期','date'),
  title('名称','title');

  const SortType(this.name, this.value);
  final String name;
  final String value;
}