import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/pages/characters/provider/characters_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/bgm_utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

/// 角色列表页面
class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoFillChecked = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

    return Consumer(
      builder: (context, ref, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.metrics.axis == Axis.vertical) {
              ref
                  .read(charactersListProvider.notifier)
                  .onScroll(notification.metrics);
            }
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Consumer(
                builder: (context, ref, _) {
                  final charactersAsync = ref.watch(charactersListProvider);
                  final total = charactersAsync.asData?.value.characters.total;
                  return Text(
                    '角色${total != null ? '($total)' : ''}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: Consumer(
                  builder: (context, ref, _) {
                    final charactersAsync = ref.watch(charactersListProvider);

                    return charactersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => const Center(
                        child: Text('加载角色信息失败'),
                      ),
                      data: (viewState) {
                        final charactersData = viewState.characters;
                        if (charactersData.data.isEmpty) {
                          return const Center(
                            child: Text('暂无角色信息'),
                          );
                        }

                        final effectiveWidth =
                            screenWidth.clamp(0.0, maxWidth - 32);
                        final crossAxisCount =
                            _calculateCrossAxisCount(effectiveWidth);

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_autoFillChecked ||
                              !_scrollController.hasClients) {
                            return;
                          }
                          _autoFillChecked = true;
                          ref
                              .read(charactersListProvider.notifier)
                              .maybeAutoFillShortContent(
                                _scrollController.position,
                              );
                        });

                        return GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: itemHeight,
                          ),
                          itemCount: charactersData.data.length + 1,
                          itemBuilder: (context, index) {
                            if (index == charactersData.data.length) {
                              return SizedBox(
                                height: itemHeight,
                                child: viewState.hasMore
                                    ? viewState.isLoadingMore
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : const SizedBox.shrink()
                                    : const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('没有更多了'),
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
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
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
          CharacterInfoRoute(
            id: characterData.character.id,
            name: characterData.character.nameCN.isNotEmpty
                ? characterData.character.nameCN
                : characterData.character.name,
            image: characterData.character.images.large,
          ).push(context);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    characterData.character.nameCN.isEmpty
                        ? characterData.character.name
                        : characterData.character.nameCN,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (characterData.character.nameCN.isNotEmpty &&
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
                        color: primary,
                      ),
                    ),
                  ),
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
                  if (characterData.actors.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: characterData.actors.take(2).map((actor) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (actor.images.medium.isNotEmpty) ...[
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: AnimationNetworkImage(
                                  borderRadius: BorderRadius.circular(6),
                                  url: actor.images.medium,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                actor.nameCN ?? actor.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: textFontWeight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
