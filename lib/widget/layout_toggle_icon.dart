import 'package:flutter/material.dart';

class LayoutToggleIcon extends StatefulWidget {
  const LayoutToggleIcon({
    super.key,
    required this.isGridView,
    this.size,
    this.color,
  });

  final bool isGridView;
  final double? size;
  final Color? color;

  @override
  State<LayoutToggleIcon> createState() => _LayoutToggleIconState();
}

class _LayoutToggleIconState extends State<LayoutToggleIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.isGridView ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant LayoutToggleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGridView == widget.isGridView) {
      return;
    }
    if (widget.isGridView) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(
      icon: AnimatedIcons.view_list,
      progress: _controller,
      size: widget.size,
      color: widget.color,
    );
  }
}
