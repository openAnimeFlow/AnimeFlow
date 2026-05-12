import 'package:anime_flow/constants/image_path_constants.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bangumi OAuth 应用回调处理页面
class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({
    super.key,
    required this.callbackUri,
  });

  final Uri callbackUri;

  /// 完成后进入主页 [MainPage] 的底栏索引（0 推荐 / 1 排行 / 2 我的）

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final CurvedAnimation _pulse;
  // todo 默认回到“我的”，后续可配置默认跳转页面
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

  MyController _ensureMyController() {
    if (Get.isRegistered<MyController>()) {
      return Get.find<MyController>();
    }
    return Get.put(MyController(), permanent: true);
  }

  Future<void> _runCallback() async {
    final controller = _ensureMyController();
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
                    _OAuthBrandPulse(
                      pulse: _pulse,
                      colorScheme: cs,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      '正在完成登录',
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '正在安全连接 Bangumi 并同步账号信息，请稍候',
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
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: cs.primary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OAuth 安全回调',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
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

class _OAuthBrandPulse extends StatelessWidget {
  const _OAuthBrandPulse({
    required this.pulse,
    required this.colorScheme,
  });

  final Animation<double> pulse;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        final scale = 1.0 + 0.04 * t;

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            AssetsPathConstants.logo,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.account_circle_rounded,
              size: 72,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
