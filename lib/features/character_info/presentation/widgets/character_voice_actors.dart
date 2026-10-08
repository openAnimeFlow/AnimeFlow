import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';

class CharacterVoiceActorsView extends StatelessWidget {
  const CharacterVoiceActorsView({super.key, required this.casts});

  final List<CharacterCast> casts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceActorsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (casts.isEmpty)
          Text(l10n.noVoiceActors)
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: casts
                  .map((cast) => SizedBox(
                        width: width,
                        child: _VoiceActorCard(cast: cast),
                      ))
                  .toList(),
            );
          }),
      ],
    );
  }
}

class _VoiceActorCard extends StatelessWidget {
  const _VoiceActorCard({required this.cast});

  final CharacterCast cast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final person = cast.person;
    final nameCN = person.nameCN ?? '';
    final name = nameCN.isEmpty ? person.name : nameCN;
    final image = person.images.large.isNotEmpty
        ? person.images.large
        : person.images.medium.isNotEmpty
            ? person.images.medium
            : person.images.small.isNotEmpty
                ? person.images.small
                : person.images.grid;
    final careers = person.career.map((career) => switch (career) {
          'seiyu' => l10n.voiceActorCareerSeiyu,
          'actor' => l10n.voiceActorCareerActor,
          'artist' => l10n.voiceActorCareerArtist,
          _ => career,
        });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image.isNotEmpty) ...[
          GestureDetector(
            onTap: () => ImagePreviewRoute.fromArgs(
              ImageViewerRouteArgs(imageUrls: [image]),
            ).push(context),
            child: AnimationNetworkImage(
              url: image,
              width: 64,
              height: 80,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              if (nameCN.isNotEmpty && nameCN != person.name)
                Text(person.name),
              if (person.info.isNotEmpty) Text(person.info),
              if (person.career.isNotEmpty)
                Text(l10n.voiceActorCareers(careers.join(' / '))),
              Text(l10n.commentCount(person.comment)),
              if (cast.summary.isNotEmpty) Text(cast.summary),
            ],
          ),
        ),
      ],
    );
  }
}
