import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scoped by the settings shell, including direct child-route navigation.
final settingsLayoutProvider = Provider.autoDispose<bool>(
  (ref) => false,
  dependencies: const [],
);
