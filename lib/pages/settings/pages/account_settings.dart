import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/providers/user/user_oauth_state.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: const Text('账户设置'),
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
                return _buildNotLoggedIn(context);
              }
              return userInfoAsync.when(
                data: (user) => user == null
                    ? _buildNotLoggedIn(context)
                    : _buildLoggedInContent(
                        context,
                        ref,
                        user,
                        bangumiBindAsync,
                        isBinding,
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildErrorState('获取用户资料失败'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState('加载登录状态失败'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(userControllerProvider.notifier).clearUserInfo();
    if (!context.mounted) return;
    NotificationToast.show('提示', '已退出登录');
  }

  Future<void> _bindBangumi(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userControllerProvider.notifier).openOAuthPageForBind();
      if (!context.mounted) return;
      NotificationToast.show('提示', '请在浏览器完成授权后返回应用');
    } catch (e) {
      if (!context.mounted) return;
      final message = e is AnimeFlowApiException
          ? e.message
          : e is StateError
              ? e.message
              : '打开授权页面失败';
      NotificationToast.show('提示', message);
    }
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  '尚未登录',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '登录后可管理账户信息、绑定 Bangumi 账号',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => const LoginRoute().push(context),
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('登录'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => const RegisterRoute().push(context),
                  child: const Text('注册新账号'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInContent(
    BuildContext context,
    WidgetRef ref,
    FlowUsers user,
    AsyncValue<BangumiBindItem?> bangumiBindAsync,
    bool isBinding,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('账户信息'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: user.avatar.isNotEmpty
                      ? AnimationNetworkImage(
                          url: user.avatar,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname.isNotEmpty ? user.nickname : user.email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      if (user.createTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '注册于 ${user.createTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('第三方账号'),
        _buildBangumiBindCard(
          context,
          ref,
          bangumiBindAsync,
          isBinding,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('账户操作'),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '退出登录',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, ref),
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

    if (isBinding) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '正在等待 Bangumi 授权结果...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(userControllerProvider.notifier).cancelOAuthWaiting(),
                child: const Text('取消'),
              ),
            ],
          ),
        ),
      );
    }

    return bangumiBindAsync.when(
      data: (bind) => _buildBangumiBindContent(context, ref, bind),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: ListTile(
          leading: SvgPicture.asset(
            AssetsPathConstants.bangumi,
            width: 28,
            height: 28,
          ),
          title: const Text('Bangumi'),
          subtitle: const Text('获取绑定状态失败'),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(bangumiBindProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBangumiBindContent(
    BuildContext context,
    WidgetRef ref,
    BangumiBindItem? bind,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBound = bind?.bound ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  AssetsPathConstants.bangumi,
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                        isBound ? '已绑定' : '未绑定',
                        style: TextStyle(
                          color: isBound
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBound && bind!.platformUid != null)
                  Text(
                    '#${bind.platformUid}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (isBound &&
                (bind!.nickname?.isNotEmpty == true ||
                    bind.username?.isNotEmpty == true)) ...[
              const SizedBox(height: 12),
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
                        if (bind.nickname?.isNotEmpty == true)
                          Text(bind.nickname!),
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
              const SizedBox(height: 16),
              Text(
                '绑定 Bangumi 账号后可同步收藏等数据',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _bindBangumi(context, ref),
                icon: SvgPicture.asset(
                  AssetsPathConstants.bangumi,
                  width: 18,
                  height: 18,
                ),
                label: const Text('绑定 Bangumi 账号'),
              ),
            ],
          ],
        ),
      ),
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
