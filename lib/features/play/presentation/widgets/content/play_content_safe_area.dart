import 'package:flutter/material.dart';

/// Owns system insets for the tabs and their nested content. In the wide
/// layout the panel is on the right, so the display's left inset is unrelated.
class PlayContentSafeArea extends StatelessWidget {
  const PlayContentSafeArea({
    super.key,
    required this.isWideScreen,
    required this.child,
  });

  final bool isWideScreen;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.removePadding(
        context: context,
        removeLeft: isWideScreen,
        child: SafeArea(
          left: !isWideScreen,
          bottom: false,
          child: child,
        ),
      );
}
