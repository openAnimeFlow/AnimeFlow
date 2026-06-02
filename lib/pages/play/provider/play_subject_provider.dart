import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_subject_provider.g.dart';

@Riverpod(dependencies: [])
PlayRouteExtra playRouteExtra(Ref ref) {
  throw UnimplementedError('playRouteExtraProvider must be overridden');
}

@Riverpod(dependencies: [PlaySubjectState])
PlayExtra playSubject(Ref ref) {
  return ref.watch(playSubjectStateProvider).subject;
}

@Riverpod(dependencies: [PlaySubjectState])
int playContinueEpisode(Ref ref) {
  return ref.watch(playSubjectStateProvider).continueEpisode;
}

class PlaySubjectValue {
  const PlaySubjectValue({
    required this.subject,
    this.continueEpisode = 0,
  });

  final PlayExtra subject;
  final int continueEpisode;

  PlaySubjectValue copyWith({
    PlayExtra? subject,
    int? continueEpisode,
  }) {
    return PlaySubjectValue(
      subject: subject ?? this.subject,
      continueEpisode: continueEpisode ?? this.continueEpisode,
    );
  }
}

@Riverpod(dependencies: [playRouteExtra])
class PlaySubjectState extends _$PlaySubjectState {
  @override
  PlaySubjectValue build() {
    final extra = ref.watch(playRouteExtraProvider);
    return PlaySubjectValue(
      subject: extra.playExtra,
      continueEpisode: extra.continueEpisode ?? 0,
    );
  }

  void setContinueEpisode(int episode) {
    state = state.copyWith(continueEpisode: episode);
  }
}
