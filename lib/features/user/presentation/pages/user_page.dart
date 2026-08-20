import 'package:anime_flow/features/auth/presentation/pages/login_page.dart';
import 'package:anime_flow/features/user/presentation/widgets/user_view.dart';
import 'package:anime_flow/features/user/application/user_controller.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

enum _NoLoginOverflowAction { settings, playRecord }

/// 用户页
class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLoggedInAsync = ref.watch(isLoggedInProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return isLoggedInAsync.when(
      data: (isLoggedIn) {
        if (!isLoggedIn) {
          return _buildLoginPage(context, colorScheme);
        }

        ref.listen<AsyncValue<dynamic>>(currentUserInfoProvider,
            (previous, next) {
          final shouldNotifyNull = next is AsyncData &&
              next.value == null &&
              previous?.value != null;
          final shouldNotifyError = next is AsyncError;
          if (!shouldNotifyNull && !shouldNotifyError) {
            return;
          }

          final message =
              shouldNotifyError ? l10n.profileLoadFailed : l10n.profileExpired;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            NotificationToast.show(message,
                title: l10n.tip, align: Alignment.topCenter);
          });
        });

        final userInfoAsync = ref.watch(currentUserInfoProvider);
        return userInfoAsync.when(
          data: (userInfo) => userInfo == null
              ? Scaffold(
                  body: Center(child: Text(l10n.noUserProfile)),
                )
              : UserView(user: userInfo),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.profileLoadFailed),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            ref.invalidate(currentUserInfoProvider),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(l10n.confirmLogout),
                              content: Text(l10n.logoutConfirmation),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: Text(l10n.confirm),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await ref
                                .read(userControllerProvider.notifier)
                                .clearUserInfo();
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.logout),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginPage(),
    );
  }

  Widget _buildLoginPage(BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return LoginPage(
      appBar: AppBar(
        forceMaterialTransparency: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropDownMenu<_NoLoginOverflowAction>(
              tooltip: l10n.moreMenu,
              items: _NoLoginOverflowAction.values,
              disableSelected: false,
              buttonBuilder: (context, _) => Icon(
                Icons.notes_outlined,
                size: 28,
                color: colorScheme.onSurface,
              ),
              itemBuilder: (context, action, _) {
                final (icon, label) = switch (action) {
                  _NoLoginOverflowAction.settings => (
                      Icons.settings_outlined,
                      l10n.settingsLabel
                    ),
                  _NoLoginOverflowAction.playRecord => (
                      Icons.smart_display_outlined,
                      l10n.playbackHistory
                    ),
                };
                return SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(label, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              },
              onSelected: (action) {
                switch (action) {
                  case _NoLoginOverflowAction.settings:
                    const SettingsRoute().push(context);
                  case _NoLoginOverflowAction.playRecord:
                    const PlayRecordRoute().push(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
