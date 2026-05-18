import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setting_provider.g.dart';

@riverpod
class SettingsLayout extends _$SettingsLayout {
  @override
  bool build() => false;

  void setWideScreen(bool value) {
    if (state != value) {
      state = value;
    }
  }
}
