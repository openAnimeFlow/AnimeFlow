import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:anime_flow/features/auth/presentation/pages/login_page.dart';
import 'package:anime_flow/features/settings/presentation/widgets/account/bgm_collection_sync_section.dart';
import 'package:anime_flow/features/settings/presentation/widgets/account/bind_email_section.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/user/application/user_controller.dart';
import 'package:anime_flow/features/user/application/user_oauth_state.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/network_check_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

import 'package:anime_flow/features/settings/presentation/widgets/account/account_content.dart';
import 'package:anime_flow/features/settings/presentation/widgets/account/avatar_dialog.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  bool _isAvatarUploading = false;

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmLogout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(userControllerProvider.notifier).clearUserInfo();
    if (!context.mounted) return;
    NotificationToast.show(l10n.logoutSuccess, title: l10n.tip);
  }

  Future<void> _bindBangumi() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(userControllerProvider.notifier).openOAuthPageForBind();
      if (!context.mounted) return;
    } on StateError catch (e) {
      if (!context.mounted) return;
      NotificationToast.show(e.message, title: l10n.tip);
    } catch (e) {
      if (!context.mounted) return;
      NotificationToast.show(
        resolveAnimeFlowErrorMessage(e, fallback: l10n.openAuthorizationFailed),
        title: l10n.tip,
      );
    }
  }

  Future<void> _handleAvatarUpload(
      BuildContext context, String? currentAvatar) async {
    final cropped = await AvatarDialog.pickAndCrop(
      context,
      currentAvatar: currentAvatar,
    );
    if (cropped == null) return;

    setState(() => _isAvatarUploading = true);
    try {
      final error = await ref
          .read(currentUserInfoProvider.notifier)
          .uploadAvatar(cropped);
      if (!context.mounted) return;
      if (error != null) {
        NotificationToast.show(error,
            title: '提示', duration: const Duration(seconds: 5));
        return;
      }
    } finally {
      if (mounted) setState(() => _isAvatarUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoggedInAsync = ref.watch(isLoggedInProvider);
    final userInfoAsync = ref.watch(currentUserInfoProvider);
    final bangumiBindAsync = ref.watch(bangumiBindProvider);
    final oauthState = ref.watch(userControllerProvider);
    final isBinding = oauthState.isAuthorizing &&
        oauthState.purpose == OAuthPurpose.bindBangumi;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.accountSettings),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isLoggedInAsync.when(
            data: (isLoggedIn) {
              if (!isLoggedIn) {
                return const LoginPage();
              }
              return userInfoAsync.when(
                data: (user) => user == null
                    ? _buildNotLoggedIn(context)
                    : _buildLoggedInContent(
                        context,
                        user,
                        bangumiBindAsync,
                        isBinding,
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildErrorState(l10n.profileLoadFailed),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState(l10n.loginStateLoadFailed),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.notLoggedIn,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginToManageAccount,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(children: [
                      FilledButton.icon(
                        onPressed: () => const LoginRoute().push(context),
                        icon: const Icon(Icons.login_outlined),
                        label: Text(l10n.login),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Consumer(builder: (context, ref, _) {
                              return OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(userControllerProvider.notifier)
                                      .openOAuthPage();
                                },
                                icon: SvgPicture.asset(
                                  AssetsPathConstants.bangumi,
                                  height: 20,
                                  width: 20,
                                ),
                                label: Text(
                                  l10n.authorizeLogin,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  const RegisterRoute().push(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                l10n.registerAccount,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInContent(
    BuildContext context,
    FlowUsers user,
    AsyncValue<BangumiBindItem?> bangumiBindAsync,
    bool isBinding,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(l10n.accountInfo),
        AccountContentView(
          userInfo: user,
          isAvatarUploading: _isAvatarUploading,
          onAvatarUpload: () => _handleAvatarUpload(context, user.avatar),
          onNicknameConfirm: (newNickname) async {
            final error = await ref
                .read(currentUserInfoProvider.notifier)
                .updateNickname(newNickname);
            if (error != null) {
              NotificationToast.show(error, title: l10n.tip);
              throw error;
            }
            NotificationToast.show(l10n.nicknameUpdated, title: l10n.tip);
          },
        ),
        if (user.email.isEmpty) ...[
          const SizedBox(height: 16),
          const BindEmailSection(),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle(l10n.thirdPartyAccounts),
        _buildBangumiBindCard(
          context,
          ref,
          bangumiBindAsync,
          isBinding,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(l10n.accountActions),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () => _confirmLogout(),
            title: Text(
              l10n.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBangumiBindCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<BangumiBindItem?> bangumiBindAsync,
    bool isBinding,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  AssetsPathConstants.bangumi,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBangumiStatusInfo(
                    colorScheme: colorScheme,
                    bangumiBindAsync: bangumiBindAsync,
                    isBinding: isBinding,
                  ),
                ),
                bangumiBindAsync.maybeWhen(
                  data: (bind) {
                    final isBound = bind?.bound ?? false;
                    if (!isBinding && isBound && bind?.platformUid != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Text(
                          '#${bind!.platformUid}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                NetworkCheckButton(
                  url: CommonApi.bgmTV,
                  label: 'Bangumi',
                  successHint: l10n.bangumiBindSuccessHint,
                  failureHint: l10n.bangumiBindFailureHint,
                ),
              ],
            ),
            if (isBinding) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.waitingBangumiAuthorization,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(userControllerProvider.notifier)
                        .cancelOAuthWaiting(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ] else
              bangumiBindAsync.when(
                data: (bind) => _buildBangumiBindBody(context, ref, bind),
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => ref.invalidate(bangumiBindProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBangumiStatusInfo({
    required ColorScheme colorScheme,
    required AsyncValue<BangumiBindItem?> bangumiBindAsync,
    required bool isBinding,
  }) {
    final l10n = AppLocalizations.of(context);
    return bangumiBindAsync.when(
      data: (bind) {
        final isBound = bind?.bound ?? false;
        final statusText = isBinding
            ? l10n.authorizing
            : isBound
                ? l10n.bound
                : l10n.unbound;
        final statusColor = isBinding
            ? colorScheme.onSurfaceVariant
            : isBound
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant;
        return _buildBangumiTitleColumn(statusText, statusColor);
      },
      loading: () => _buildBangumiTitleColumn(
        isBinding ? l10n.authorizing : l10n.loading,
        colorScheme.onSurfaceVariant,
      ),
      error: (_, __) => _buildBangumiTitleColumn(
        l10n.bindStatusLoadFailed,
        colorScheme.error,
      ),
    );
  }

  Widget _buildBangumiTitleColumn(String statusText, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bangumi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          statusText,
          style: TextStyle(color: statusColor),
        ),
      ],
    );
  }

  Widget _buildBangumiBindBody(
    BuildContext context,
    WidgetRef ref,
    BangumiBindItem? bind,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isBound = bind?.bound ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 18,
      children: [
        if (isBound &&
            (bind!.nickname?.isNotEmpty == true ||
                bind.username?.isNotEmpty == true)) ...[
          Row(
            children: [
              if (bind.avatar?.isNotEmpty == true)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimationNetworkImage(
                    url: bind.avatar!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.person, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bind.nickname?.isNotEmpty == true) Text(bind.nickname!),
                    if (bind.username?.isNotEmpty == true)
                      Text(
                        '@${bind.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (!isBound) ...[
          Text(
            l10n.bindBangumiHint,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton(
            onPressed: () => _bindBangumi(),
            child: Text(l10n.bindBangumiAccount),
          ),
        ],
        if (isBound) ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.confirmUnbind),
                    content: Text(l10n.unbindConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.confirmUnbindAction),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(userControllerProvider.notifier)
                      .unbindBangumi();
                }
              },
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l10n.unbind),
            ),
          ),
          const Divider(),
          const BangumiCollectionSyncSection(),
        ],
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
