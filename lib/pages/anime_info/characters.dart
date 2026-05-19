import 'dart:math';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharactersView extends StatelessWidget {
  final int subjectsId;

  const CharactersView({super.key, required this.subjectsId});


  @override
  Widget build(BuildContext context) {

    final double windowsWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(builder: (context, ref, child) {
          final asyncCharacters =
          ref.watch(subjectCharactersProvider(subjectsId));
          return asyncCharacters.when(
            data: (characters) {
              if (characters.total > 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '角色',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        InkWell(
                          onTap: () =>
                              CharactersRoute(subjectsId: subjectsId)
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
                      height: windowsWidth > 600 ? 130 : 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: characters.data.length,
                        itemBuilder: (context, index) {
                          final actor = characters.data[index];
                          return Container(
                            width: windowsWidth > 600 ? 80 : 60,
                            margin: EdgeInsets.only(
                                right: index == characters.data.length - 1
                                    ? 0
                                    : 8),
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
                                  actor.character.nameCN ??
                                      actor.character.name,
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
                                    actor.actors[0].nameCN ??
                                        actor.actors[0].name,
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
                );
              } else {
                return const SizedBox.shrink();
              }
            },
            loading: () {
              return const SizedBox.shrink();
            },
            error: (error, stackTrace) {
              LiggLogger().e('获取角色信息失败', error: error, stackTrace: stackTrace);
              return const SizedBox.shrink();
            },
          );
        }),
      ],
    );
  }
}
