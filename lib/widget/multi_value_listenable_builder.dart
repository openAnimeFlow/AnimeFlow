import 'package:flutter/widgets.dart';

class MultiValueListenableBuilder extends StatelessWidget {
  const MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
  });

  final List<Listenable> listenables;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) => builder(context),
    );
  }
}
