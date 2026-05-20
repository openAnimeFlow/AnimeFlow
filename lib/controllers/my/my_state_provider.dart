import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserInfo extends _$CurrentUserInfo {
  @override
  UserInfoItem? build() => null;

  void setUserInfo(UserInfoItem? info) {
    state = info;
  }

  void clear() {
    state = null;
  }
}

@Riverpod(keepAlive: true)
class OAuthAuthorizing extends _$OAuthAuthorizing {
  @override
  bool build() => false;

  void setAuthorizing(bool value) {
    if (state != value) {
      state = value;
    }
  }
}
