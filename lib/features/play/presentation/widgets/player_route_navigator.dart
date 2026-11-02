import 'package:flutter/material.dart';

class PlayerRouteNavigator extends StatefulWidget {
  const PlayerRouteNavigator({super.key, required this.child});

  final Widget child;

  static ModalRoute<dynamic>? outerRouteOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PlayerOuterRoute>()?.route;

  @override
  State<PlayerRouteNavigator> createState() => _PlayerRouteNavigatorState();
}

class _PlayerRouteNavigatorState extends State<PlayerRouteNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => _PlayerOuterRoute(
        route: ModalRoute.of(context),
        child: NavigatorPopHandler<void>(
          onPopWithResult: (_) => _navigatorKey.currentState!.maybePop(),
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => widget.child,
            ),
          ),
        ),
      );
}

class _PlayerOuterRoute extends InheritedWidget {
  const _PlayerOuterRoute({required this.route, required super.child});

  final ModalRoute<dynamic>? route;

  @override
  bool updateShouldNotify(_PlayerOuterRoute oldWidget) =>
      route != oldWidget.route;
}
