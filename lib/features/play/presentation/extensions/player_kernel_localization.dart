import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';

extension PlayerKernelLocalization on AppLocalizations {
  String kernelLabel(PlayerKernel kernel) => switch (kernel) {
        PlayerKernel.mediaKit => playerKernelMpv,
        PlayerKernel.fvp => playerKernelMdk,
      };
}
