part of 'synopsis.dart';
///相关条目
class _RelatedView extends StatefulWidget {
  final int subjectId;

  const _RelatedView({required this.subjectId});

  @override
  State<_RelatedView> createState() => _RelatedViewState();
}

class _RelatedViewState extends State<_RelatedView> {
  SubjectRelationItem? subjectRelation;

  @override
  void initState() {
    super.initState();
    _getSubjectRelation();
  }

  void _getSubjectRelation() async {
    final subjectRelation = await BgmRequest.relatedSubjectsService(
        widget.subjectId,
        limit: 20,
        offset: 0);
    if (mounted) {
      setState(() {
        this.subjectRelation = subjectRelation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (subjectRelation == null) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }
    if (subjectRelation!.data.isEmpty) {
      return const SizedBox.shrink();
    } else {
      final relation = subjectRelation!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '关联条目',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              relation.total > 20
                  ? TextButton(onPressed: () {}, child: const Text('查看全部'))
                  : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relation.data.length,
              // 缓存范围，优化滚动性能
              cacheExtent: 200,
              // 不自动保持item状态，节省内存
              addAutomaticKeepAlives: false,
              // 添加重绘边界，优化性能
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final item = relation.data[index];
                final subjectBasicData = SubjectBasicData(
                  id: item.subject.id,
                  name: item.subject.nameCN ?? item.subject.name,
                  image: item.subject.images.large,
                );
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 5),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(RouteName.animeInfo,
                          arguments: subjectBasicData);
                    },
                    child: Column(
                      children: [
                        AnimationNetworkImage(
                            borderRadius: BorderRadius.circular(10),
                            url: item.subject.images.large),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            item.subject.nameCN ?? item.subject.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      );
    }
  }
}
