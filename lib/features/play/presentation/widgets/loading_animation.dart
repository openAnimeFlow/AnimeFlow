import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatefulWidget {
  final bool isPlaying;
  final double? size;

  const LoadingAnimation({
    super.key,
    required this.isPlaying,
    this.size,
  });

  @override
  State<LoadingAnimation> createState() =>
      _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant LoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying == widget.isPlaying) return;
    _setPlaying(widget.isPlaying);
  }

  void _setPlaying(bool playing) {
    if (playing) {
      if (_controller.duration != null) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      AssetsPathConstants.loadingJson,
      controller: _controller,
      width: widget.size,
      height: widget.size,
      frameBuilder: (context, child, composition) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
          child: child,
        );
      },
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _setPlaying(widget.isPlaying);
      },
    );
  }
}
