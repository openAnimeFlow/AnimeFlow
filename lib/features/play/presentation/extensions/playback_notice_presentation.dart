import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';

extension PlaybackNoticePresentation on PlaybackNotice {
  String localize(AppLocalizations l10n) => switch (this) {
        PlaybackNotice.none => '',
        PlaybackNotice.resolvingSource => l10n.videoSourceResolving,
        PlaybackNotice.sourceReady => l10n.videoSourceReady,
        PlaybackNotice.openingLocalVideo => l10n.openingLocalVideo,
        PlaybackNotice.sourceResolutionTimedOut =>
          l10n.videoSourceResolutionTimedOut,
        PlaybackNotice.sourceNotFound => l10n.noPlayableSourceForEpisode,
        PlaybackNotice.sourceResolutionFailed =>
          l10n.videoSourceResolutionFailed,
        PlaybackNotice.localVideoNoTrack => l10n.localVideoNoTrack,
        PlaybackNotice.localVideoValidationTimedOut =>
          l10n.localVideoValidationTimedOut,
        PlaybackNotice.localVideoOpenFailed => l10n.localVideoOpenFailed,
        PlaybackNotice.localVideoPlaybackFailed =>
          l10n.localVideoPlaybackFailed,
        PlaybackNotice.onlineVideoPlaybackFailed =>
          l10n.onlineVideoPlaybackFailed,
      };
}
