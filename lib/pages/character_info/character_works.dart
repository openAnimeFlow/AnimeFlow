import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/character_subjects_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/bgm_utils.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CharacterWorksView extends StatefulWidget {
  final int characterId;

  const CharacterWorksView({super.key, required this.characterId});

  @override
  State<CharacterWorksView> createState() => _CharacterWorksViewState();
}

class _CharacterWorksViewState extends State<CharacterWorksView> {
  CharacterCastsItem? characterCasts;

  @override
  void initState() {
    super.initState();
    _getCharacterWorks();
  }

  ///获取出演作品
  void _getCharacterWorks() async {
    final works = await BgmRequest.characterWorksService(widget.characterId,
        limit: 20, offset: 0);
    if (mounted) {
      setState(() {
        characterCasts = works;
      });
    }
  }

  // 计算列数
  int _calculateCrossAxisCount(double screenWidth) {
    const minItemWidth = 320.0;
    if (screenWidth < 450) return 1;
    return (screenWidth / minItemWidth).floor().clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    if (characterCasts == null) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (characterCasts!.data.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('暂无出演作品'),
        ),
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
              itemCount: characterCasts!.data.length,
              itemBuilder: (context, index) {
                final work = characterCasts!.data[index];
                return _buildWorkCard(context, work, itemHeight);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkCard(
    BuildContext context,
    CharacterSubjectData work,
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
          final subjectBasicData = SubjectBasicData(
            id: work.subject.id,
            name: work.subject.nameCN ?? work.subject.name,
            image: work.subject.images.large,
          );
          Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：作品封面
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
            // 右侧：作品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 作品名称（中文）
                  Text(
                    work.subject.nameCN ?? work.subject.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 作品名称（日文）
                  if (work.subject.nameCN != null &&
                      work.subject.nameCN != work.subject.name) ...[
                    const SizedBox(height: 2),
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
                  ],
                  const SizedBox(height: 2),
                  // 角色类型标签
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
                  // 声优信息
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
