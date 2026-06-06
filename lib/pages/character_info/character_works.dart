import 'package:anime_flow/models/item/bangumi/character_subjects_item.dart';
import 'package:anime_flow/pages/character_info/provider/character_info_provider.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/bgm_utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharacterWorksView extends StatelessWidget {
  const CharacterWorksView({super.key});

  int _calculateCrossAxisCount(double screenWidth) {
    const minItemWidth = 320.0;
    if (screenWidth < 450) return 1;
    return (screenWidth / minItemWidth).floor().clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final worksAsync = ref.watch(characterWorksProvider);

        return worksAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SliverFillRemaining(
            child: Center(child: Text('加载出演作品失败')),
          ),
          data: (characterCasts) {
            if (characterCasts.data.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('暂无出演作品')),
              );
            }

            final screenWidth = MediaQuery.of(context).size.width - 32;
            const maxWidth = 1400.0;
            const double itemHeight = 160.0;
            final effectiveWidth = screenWidth.clamp(0.0, maxWidth - 32);
            final crossAxisCount = _calculateCrossAxisCount(effectiveWidth);

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxWidth),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: itemHeight,
                      ),
                      itemCount: characterCasts.data.length,
                      itemBuilder: (context, index) {
                        final work = characterCasts.data[index];
                        return _buildWorkCard(context, work, itemHeight);
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkCard(
    BuildContext context,
    CharacterSubjectData work,
    double itemHeight,
  ) {
    final disabledColor = Theme.of(context).disabledColor;
    final primary = Theme.of(context).colorScheme.primary;
    const textFontWeight = FontWeight.w600;

    return SizedBox(
      height: itemHeight,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          AnimeInfoRoute.fromExtra(InfoRouteExtra(
            id: work.subject.id,
            name: work.subject.nameCN.isEmpty
                ? work.subject.name
                : work.subject.nameCN,
            image: work.subject.images.large,
          )).push(context);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: itemHeight,
              width: 110,
              child: AnimationNetworkImage(
                alignment: Alignment.topCenter,
                borderRadius: BorderRadius.circular(10),
                url: work.subject.images.large,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (work.subject.nameCN.isNotEmpty)
                    Text(
                      work.subject.nameCN,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      work.subject.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  if (work.subject.name.isNotEmpty)
                    Text(
                      work.subject.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: textFontWeight,
                        color: disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      BgmUtils.getCharacterType(work.type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: textFontWeight,
                        color: primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (work.actors.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: work.actors.take(2).map((actor) {
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
