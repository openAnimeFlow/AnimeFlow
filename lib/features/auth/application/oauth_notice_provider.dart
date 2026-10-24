import 'package:flutter_riverpod/flutter_riverpod.dart';

class OAuthNotice {
  const OAuthNotice(this.message, this.duration);
  final String message;
  final Duration duration;
}

final oauthNoticeProvider =
    NotifierProvider<OAuthNotices, OAuthNotice?>(OAuthNotices.new);

class OAuthNotices extends Notifier<OAuthNotice?> {
  @override
  OAuthNotice? build() => null;

  void publish(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    state = OAuthNotice(message, duration);
  }
}
