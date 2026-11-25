import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/debounced_image_width.dart';
import 'package:material_ui/material_ui.dart';

class CharactersView extends StatelessWidget {
  const CharactersView({super.key, required this.characters});

  final List<CharacterActorData> characters;

  @override
  Widget build(BuildContext context) {
    final windowsWidth = MediaQuery.sizeOf(context).width;
    final avatarWidth = windowsWidth > 600 ? 80.0 : 60.0;
    return SizedBox(
      height: windowsWidth > 600 ? 130 : 120,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final actor = characters[index];
            return Container(
              width: avatarWidth,
              margin: EdgeInsets.only(
                  right: index == characters.length - 1 ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  // 角色头像
                  InkWell(
                    onTap: () => appNavigatorOf(context)
                        .openCharacterInfo<void>(
                            id: actor.character.id,
                            name: actor.character.nameCN.isEmpty
                                ? actor.character.name
                                : actor.character.nameCN,
                            image: actor.character.images.large,
                            extra: CharacterInfoExtra(
                              characterId: actor.character.id,
                              characterName: actor.character.name,
                              characterImage: actor.character.images.large,
                              casts: actor.casts,
                            )),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DebouncedImageWidth(
                        width: avatarWidth,
                        builder: (context, cacheWidth) => AnimationNetworkImage(
                          memCacheWidth: cacheWidth,
                          gaplessResize: true,
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
                    actor.character.nameCN.isEmpty
                        ? actor.character.name
                        : actor.character.nameCN,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
