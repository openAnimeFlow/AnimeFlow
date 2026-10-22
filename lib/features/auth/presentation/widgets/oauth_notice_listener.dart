import 'package:anime_flow/features/auth/application/oauth_notice_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';

class OAuthNoticeListener extends ConsumerWidget {
  const OAuthNoticeListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(oauthNoticeProvider, (_, notice) {
      if (notice != null) {
        NotificationToast.show(notice.message,
            title: '提示', duration: notice.duration);
      }
    });
    return child;
  }
}
