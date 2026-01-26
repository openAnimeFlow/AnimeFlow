import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_ite.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/bgm_utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///角色页面
class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  late int subjectsId;
  CharactersItem? characters;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    subjectsId = Get.arguments as int;
    _getCharacters();

    // 监听滚动，触发加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  ///获取角色信息
  void _getCharacters({bool loadMore = false}) async {
    // 如果正在加载，则不再加载
    if (_isLoading) return;

    // 如果是加载更多，但没有更多数据，则不加载
    if (loadMore && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _offset = 0;
        _hasMore = true;
      }
    });

    try {
      final offset = loadMore ? _offset : 0;
      final value = await BgmRequest.charactersService(
        subjectsId,
        limit: _limit,
        offset: offset,
      );
      if (mounted) {
        setState(() {
          if (loadMore && characters != null) {
            // 追加数据
            characters = CharactersItem(
              data: [...characters!.data, ...value.data],
              total: value.total,
            );
          } else {
            // 首次加载
            characters = value;
          }
          _offset = offset + value.data.length;
          _hasMore = value.data.length == _limit &&
              characters!.data.length < value.total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 加载更多
  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _getCharacters(loadMore: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 计算列数
  int _calculateCrossAxisCount(double screenWidth) {
    const minItemWidth = 320.0;
    if (screenWidth < 450) return 1;
    return (screenWidth / minItemWidth).floor().clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    const maxWidth = 1400.0;
    const double itemHeight = 160.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '角色${characters != null ? '(${characters!.total})' : ''}',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Builder(builder: (context) {
            if (characters == null && _isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (characters == null || characters!.data.isEmpty) {
              return const Center(
                child: Text('暂无角色信息'),
              );
            }

            final charactersData = characters!;

            final effectiveWidth = screenWidth.clamp(0.0, maxWidth - 32);
            final crossAxisCount = _calculateCrossAxisCount(effectiveWidth);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: itemHeight,
                ),
                itemCount: charactersData.data.length + 1,
                itemBuilder: (context, index) {
                  // 如果是最后一项，显示加载指示器或"没有更多了"
                  if (index == charactersData.data.length) {
                    return SizedBox(
                      height: itemHeight,
                      child: _hasMore
                          ? _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : const SizedBox.shrink()
                          : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("没有更多了"),
                              ),
                            ),
                    );
                  }

                  final characterData = charactersData.data[index];
                  return _buildCharacterCard(
                    context,
                    characterData,
                    itemHeight,
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    CharacterActorData characterData,
    double itemHeight,
  ) {
    final disabledColor = Get.theme.disabledColor;
    final primary = Get.theme.colorScheme.primary;
    const textFontWeight = FontWeight.w600;

    return SizedBox(
      height: itemHeight,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Get.toNamed(RouteName.characterInfo, arguments: {
            'characterId': characterData.character.id,
            'characterName':
                characterData.character.nameCN ?? characterData.character.name,
            'characterImage': characterData.character.images.large,
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：角色封面
            SizedBox(
              height: itemHeight,
              width: 110,
              child: Hero(
                tag: 'character:${characterData.character.images.large}',
                child: AnimationNetworkImage(
                  alignment: Alignment.topCenter,
                  borderRadius: BorderRadius.circular(10),
                  url: characterData.character.images.medium,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧：角色信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 角色名称（中文）
                  Text(
                    characterData.character.nameCN ??
                        characterData.character.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 角色名称（日文）
                  if (characterData.character.nameCN != null &&
                      characterData.character.nameCN !=
                          characterData.character.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      characterData.character.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: textFontWeight,
                        color: disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // 角色类型
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      BgmUtils.getCharacterType(characterData.type),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: textFontWeight,
                          color: primary),
                    ),
                  ),

                  // 角色信息
                  if (characterData.character.info.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      characterData.character.info,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: textFontWeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  // 声优信息
                  if (characterData.actors.isNotEmpty) ...[
                    ...characterData.actors.take(2).map((actor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (actor.images.medium.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: AnimationNetworkImage(
                                    url: actor.images.medium,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    actor.nameCN ?? actor.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: textFontWeight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (actor.nameCN != null &&
                                      actor.nameCN != actor.name)
                                    Text(
                                      actor.name,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: textFontWeight,
                                        color: disabledColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
