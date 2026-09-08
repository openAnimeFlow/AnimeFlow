import 'dart:async';

import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/app_update/presentation/widgets/version_update_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/features/app_update/application/app_info_state.dart';

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
  late final AppInfo _appInfoNotifier;

  @override
  void initState() {
    super.initState();
    _appInfoNotifier = ref.read(appInfoProvider.notifier);
    _appInfoSubscription = ref.listenManual(
      appInfoProvider,
      (previous, next) async => _handlePendingVersionResult(next),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_appInfoNotifier.triggerStartupVersionCheck());
      _handlePendingVersionResult(ref.read(appInfoProvider));
    });
  }

  Future<void> _handlePendingVersionResult(AppInfoState state) async {
    final result = state.pendingStartupVersionResult;
    if (result == null || !mounted) return;

    final navigatorContext =
        appRouter.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handlePendingVersionResult(ref.read(appInfoProvider));
      });
      return;
    }

    _appInfoNotifier.consumeStartupVersionResult();

    await handleVersionCheckResult(
      navigatorContext,
      result,
      onStartDownload: _appInfoNotifier.performUpdateDownload,
      onDownloadedPackageAction: _appInfoNotifier.openDownloadedPackage,
      onCancelDownload: _appInfoNotifier.cancelUpdateDownload,
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
