import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/auth/presentation/pages/login_page.dart';
import 'package:anime_flow/features/user/presentation/widgets/user_center_view.dart';
import 'package:anime_flow/features/user/application/user_state_provider.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

enum _NoLoginOverflowAction {
  settings(Icons.settings_outlined),
  playRecord(Icons.smart_display_outlined),
  downloads(Icons.cloud_download_outlined);

  const _NoLoginOverflowAction(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
        _NoLoginOverflowAction.settings => l10n.settings,
        _NoLoginOverflowAction.playRecord => l10n.playbackHistory,
        _NoLoginOverflowAction.downloads => l10n.downloadsTitle,
      };
}

/// 用户页
class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  Widget _buildOverflowMenu(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return JellyMenu<_NoLoginOverflowAction>(
      tooltip: l10n.moreMenu,
      triggerColor: Colors.transparent,
      preferredVerticalDirection: VerticalDirection.down,
      trigger: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.notes_outlined, size: 28, color: colors.onSurface),
      ),
      menuBuilder: (context, select) {
        final style = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: colors.onSurface,
          textStyle: theme.textTheme.bodyLarge,
          padding: JellyMenu.itemPadding(context),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final action in _NoLoginOverflowAction.values)
                  TextButton(
                    style: style,
                    onPressed: () => select(action),
                    child: Row(
                      children: [
                        Icon(action.icon,
                            size: 20, color: colors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            action.label(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      onSelected: (action) {
        switch (action) {
          case _NoLoginOverflowAction.settings:
            appNavigatorOf(context)
                .openSettings<void>(destination: SettingsDestination.menu);
          case _NoLoginOverflowAction.playRecord:
            appNavigatorOf(context).openPlayRecord<void>();
          case _NoLoginOverflowAction.downloads:
            appNavigatorOf(context).openDownload<void>();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLoggedInAsync = ref.watch(isLoggedInProvider);
    // Keep the login page visible while the login state reloads, so a
    // successful login only shows one loading state (the profile request below)
    // instead of two full-screen spinners in a row.
    return isLoggedInAsync.when(
      data: (isLoggedIn) {
        if (!isLoggedIn) {
          return LoginPage(
            appBar: AppBar(
              forceMaterialTransparency: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildOverflowMenu(context, l10n),
                ),
              ],
            ),
          );
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
          // Login invalidates the previous session's cached null profile.
          // Show loading until the new profile request has completed.
          skipLoadingOnRefresh: false,
          data: (userInfo) => userInfo == null
              ? Scaffold(
                  body: Center(child: Text(l10n.noUserProfile)),
                )
              : UserCenterView(user: userInfo),
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
                                .read(accountControllerProvider)
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
}
