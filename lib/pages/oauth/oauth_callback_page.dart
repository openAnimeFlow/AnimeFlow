import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/providers/user/user_oauth_state.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bangumi OAuth 应用回调处理页面
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({
    super.key,
    required this.callbackUri,
  });

  final Uri callbackUri;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCallback());
  }

  Future<void> _runCallback() async {
    OAuthPurpose purpose = OAuthPurpose.login;
    try {
      final result = await ref
          .read(userControllerProvider.notifier)
          .handleDeepLink(widget.callbackUri.toString());
      purpose = result.purpose;
      if (!mounted) return;

      if (!result.success && result.errorMessage != null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              purpose == OAuthPurpose.bindBangumi
                  ? 'Bangumi 绑定失败'
                  : 'Bangumi 授权登录失败',
            ),
            content: Text(result.errorMessage!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } catch (e, st) {
      LiggLogger().e('OAuth 回调处理失败', error: e, stackTrace: st);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('授权处理失败'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        const UserRoute().go(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isBinding =
        ref.watch(userControllerProvider).purpose == OAuthPurpose.bindBangumi;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(cs.primaryContainer, cs.surface, 0.45)!,
              cs.surface,
              Color.lerp(cs.secondaryContainer, cs.surface, 0.55)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isBinding
                          ? '正在绑定 Bangumi 账号，请稍候'
                          : '正在连接 Bangumi 并同步账号信息，请稍候',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: cs.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
