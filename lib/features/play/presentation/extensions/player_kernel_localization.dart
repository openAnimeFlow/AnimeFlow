import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:flutter/foundation.dart';

extension PlayerKernelLocalization on AppLocalizations {
  String kernelLabel(PlayerKernel kernel) => switch (kernel) {
        PlayerKernel.mediaKit => playerKernelMpv,
        PlayerKernel.fvp => playerKernelMdk,
        PlayerKernel.videoPlayer => switch (defaultTargetPlatform) {
            TargetPlatform.android => 'ExoPlayer',
            TargetPlatform.iOS || TargetPlatform.macOS => 'AVPlayer',
            _ => 'Video Player',
          },
      };
}
