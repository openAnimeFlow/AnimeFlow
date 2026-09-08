import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setting_provider.g.dart';

/// Scoped by the settings shell, including direct child-route navigation.
@Riverpod(dependencies: [])
bool settingsLayout(Ref ref) => false;
