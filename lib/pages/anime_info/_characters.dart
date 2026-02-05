part of 'synopsis.dart';

class _CharactersView extends StatefulWidget {
  final int subjectsId;

  const _CharactersView({ required this.subjectsId});

  @override
  State<_CharactersView> createState() => _CharactersViewState();
}

class _CharactersViewState extends State<_CharactersView> {
  CharactersItem? characters;

  @override
  void initState() {
    super.initState();
    _getCharacters();
  }

  ///获取角色信息
  void _getCharacters() async {
    final characters = await BgmRequest.charactersService(widget.subjectsId,
        limit: 10, offset: 0);
    if (mounted) {
      setState(() {
        this.characters = characters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // 角色列表
        if (characters == null)
          //TODO 优化使用骨架屏
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (characters!.data.isEmpty)
          const SizedBox.shrink()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '角色',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  InkWell(
                    onTap: () => Get.toNamed(RouteName.characters,
                        arguments: widget.subjectsId),
                    child: Row(
                      children: [
                        Text(
                          '查看详情',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).disabledColor),
                        ),
                        Transform.rotate(
                          angle: 3 * pi / 2,
                          child: Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            color: Theme.of(context).disabledColor,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: characters!.data.length,
                  cacheExtent: 200,
                  // 缓存范围，优化滚动性能
                  addAutomaticKeepAlives: false,
                  // 不自动保持item状态，节省内存
                  addRepaintBoundaries: true,
                  // 添加重绘边界，优化性能
                  itemBuilder: (context, index) {
                    final actor = characters!.data[index];
                    return Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 角色头像
                          InkWell(
                            onTap: () => Get.toNamed(RouteName.characterInfo,
                                arguments: {
                                  'characterId': actor.character.id,
                                  'characterName': actor.character.nameCN ??
                                      actor.character.name,
                                  'characterImage':
                                      actor.character.images.large,
                                }),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Hero(
                                tag:
                                    'character:${actor.character.images.large}',
                                child: AnimationNetworkImage(
                                  borderRadius: BorderRadius.circular(10),
                                  url: actor.character.images.large,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 角色名称
                          Text(
                            actor.character.nameCN ?? actor.character.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // 声优名称
                          if (actor.actors.isNotEmpty)
                            Text(
                              actor.actors[0].nameCN ?? actor.actors[0].name,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).disabledColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          // 评论数
                          Text(
                            '+${actor.character.comment}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
