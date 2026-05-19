
import 'dart:math';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';

class CharactersView extends StatefulWidget {
  final int subjectsId;

  const CharactersView({required this.subjectsId});

  @override
  State<CharactersView> createState() => _CharactersViewState();
}

class _CharactersViewState extends State<CharactersView> {
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

  double _getWindowsWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
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
                    onTap: () =>
                        CharactersRoute(subjectsId: widget.subjectsId)
                            .push(context),
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
                height: _getWindowsWidth(context) > 600 ? 130 : 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: characters!.data.length,
                  // 缓存范围，优化滚动性能
                  addAutomaticKeepAlives: false,
                  // 不自动保持item状态，节省内存
                  addRepaintBoundaries: true,
                  // 添加重绘边界，优化性能
                  itemBuilder: (context, index) {
                    final actor = characters!.data[index];
                    return Container(
                      width: _getWindowsWidth(context) > 600 ? 80 : 60,
                      margin: EdgeInsets.only(
                          right: index == characters!.data.length - 1 ? 0 : 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 3,
                        children: [
                          // 角色头像
                          InkWell(
                            onTap: () => CharacterInfoRoute(
                              id: actor.character.id,
                              name: actor.character.nameCN ??
                                  actor.character.name,
                              image: actor.character.images.large,
                            ).push(context),
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
                          // 角色名称
                          Text(
                            actor.character.nameCN ?? actor.character.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
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
