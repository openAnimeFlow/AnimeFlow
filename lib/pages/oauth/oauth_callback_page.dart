import 'package:anime_flow/features/my/my_controller_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bangumi OAuth 应用回调处理页面
class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({
    super.key,
    required this.callbackUri,
  });

  final Uri callbackUri;

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final CurvedAnimation _pulse;
  final int returnTab = 2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCallback());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runCallback() async {
    final container = ProviderScope.containerOf(context);
    final controller = container.read(myControllerProvider);
    try {
      await controller.handleDeepLink(widget.callbackUri.toString());
    } catch (e, st) {
      LiggLogger().e('OAuth 回调处理失败', error: e, stackTrace: st);
    } finally {
      if (mounted) {
        MainRoute(tab: returnTab.clamp(0, 2)).go(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                      '正在连接 Bangumi 并同步账号信息，请稍候',
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
