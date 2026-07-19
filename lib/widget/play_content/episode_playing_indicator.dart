import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EpisodePlayingIndicator extends StatelessWidget {
  const EpisodePlayingIndicator({
    super.key,
    required this.size,
    required this.isPlaying,
  });

  final double size;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      AssetsPathConstants.playJsonIng,
      width: size,
      height: size,
      animate: isPlaying,
      frameBuilder: (context, child, composition) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
          child: child,
        );
      },
    );
  }
}
