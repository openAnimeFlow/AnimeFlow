import 'dart:async';

import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/version_update_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/app/app_info_provider.dart';
import 'features/app/app_info_state.dart';

class AppVersionUpdateListener extends ConsumerStatefulWidget {
  const AppVersionUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppVersionUpdateListener> createState() =>
      _AppVersionUpdateListenerState();
}

class _AppVersionUpdateListenerState
    extends ConsumerState<AppVersionUpdateListener> {
  ProviderSubscription<AppInfoState>? _appInfoSubscription;

  @override
  void initState() {
    super.initState();
    _appInfoSubscription = ref.listenManual(
      appInfoProvider,
          (previous, next) async => _handlePendingVersionResult(next),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(appInfoProvider.notifier).triggerStartupVersionCheck());
      _handlePendingVersionResult(ref.read(appInfoProvider));
    });
  }

  Future<void> _handlePendingVersionResult(AppInfoState state) async {
    final result = state.pendingStartupVersionResult;
    if (result == null || !mounted) return;

    final navigatorContext = appRouter.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handlePendingVersionResult(ref.read(appInfoProvider));
      });
      return;
    }

    ref.read(appInfoProvider.notifier).consumeStartupVersionResult();

    await handleVersionCheckResult(
      navigatorContext,
      result,
      onStartDownload: ref.read(appInfoProvider.notifier).performUpdateDownload,
      onCancelDownload: ref.read(appInfoProvider.notifier).cancelUpdateDownload,
    );
  }

  @override
  void dispose() {
    _appInfoSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}