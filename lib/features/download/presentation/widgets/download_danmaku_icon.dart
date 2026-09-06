import 'package:flutter/material.dart';

/// Uses the player's danmaku symbol with a download arrow.
class DownloadDanmakuIcon extends StatelessWidget {
  const DownloadDanmakuIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            child: Icon(Icons.subtitles_outlined, size: 20),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_rounded, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
