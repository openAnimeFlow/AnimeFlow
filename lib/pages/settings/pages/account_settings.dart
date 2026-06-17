import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/http/clients/flow_client.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/pages/login/index.dart';
import 'package:anime_flow/pages/settings/pages/bind_email_section.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/providers/user/bgm_collection_sync_provider.dart';
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
                return const LoginPage();
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
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(children: [
                      FilledButton.icon(
                        onPressed: () => const LoginRoute().push(context),
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('登录'),
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
                                label: const Text(
                                  '授权登录',
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
                              child: const Text(
                                '注册账号',
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.nickname.isNotEmpty
                                ? user.nickname
                                : user.email,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.edit))
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isNotEmpty ? user.email : '未绑定邮箱',
                        style: TextStyle(
                          color: user.email.isNotEmpty
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.primary,
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
        if (user.email.isEmpty) ...[
          const SizedBox(height: 16),
          const BindEmailSection(),
        ],
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
            onTap: () => _confirmLogout(context, ref),
            title: Text(
              '退出登录',
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
                onPressed: () => ref
                    .read(userControllerProvider.notifier)
                    .cancelOAuthWaiting(),
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
            if (isBound) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const _BangumiCollectionSyncSection(),
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

class _BangumiCollectionSyncSection extends ConsumerStatefulWidget {
  const _BangumiCollectionSyncSection();

  @override
  ConsumerState<_BangumiCollectionSyncSection> createState() =>
      _BangumiCollectionSyncSectionState();
}

class _BangumiCollectionSyncSectionState
    extends ConsumerState<_BangumiCollectionSyncSection> {
  bool _isSubmitting = false;

  Future<void> _triggerSync() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(bgmCollectionSyncProvider.notifier).triggerSync();
      if (!mounted) return;
      NotificationToast.show('提示', '收藏同步已开始');
    } catch (e) {
      if (!mounted) return;
      final message = e is AnimeFlowApiException
          ? e.message
          : e is StateError
              ? e.message
              : '启动同步失败';
      NotificationToast.show('提示', message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _refreshStatus() async {
    try {
      await ref.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    } catch (e) {
      if (!mounted) return;
      final message = e is AnimeFlowApiException ? e.message : '刷新状态失败';
      NotificationToast.show('提示', message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncAsync = ref.watch(bgmCollectionSyncProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return syncAsync.when(
      data: (status) {
        final item = status;
        final isRunning = item?.isRunning == true || _isSubmitting;
        final statusLabel =
            item?.status.label ?? BgmCollectionSyncStatus.idle.label;
        final message = item?.message;
        final syncedCount = item?.syncedCount ?? 0;
        final totalCount = item?.totalCount ?? 0;
        final hasProgress = isRunning && totalCount > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '收藏同步',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '刷新状态',
                  onPressed: isRunning ? null : _refreshStatus,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SyncStatusChip(
                  label: statusLabel,
                  status: item?.status ?? BgmCollectionSyncStatus.idle,
                ),
                if (isRunning) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (hasProgress) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: syncedCount / totalCount,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                '$syncedCount / $totalCount',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (isRunning && syncedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '已同步 $syncedCount 条',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRunning ? null : _triggerSync,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: Text(isRunning ? '同步进行中…' : '同步 Bangumi 收藏'),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '收藏同步',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '获取同步状态失败',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(bgmCollectionSyncProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({
    required this.label,
    required this.status,
  });

  final String label;
  final BgmCollectionSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      BgmCollectionSyncStatus.running => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      BgmCollectionSyncStatus.success => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      BgmCollectionSyncStatus.failed => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      BgmCollectionSyncStatus.idle => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
