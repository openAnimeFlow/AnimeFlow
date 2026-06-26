import 'package:anime_flow/models/item/flow/background_image_item.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/pages/settings/pages/account/provider/account_background_provider.dart';
import 'package:anime_flow/pages/settings/pages/account/user_avatar.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nickname_editor.dart';

class AccountContentView extends StatefulWidget {
  final FlowUsers userInfo;
  final VoidCallback? onAvatarUpload;
  final bool isAvatarUploading;
  final Future<void> Function(String nickname)? onNicknameConfirm;

  const AccountContentView({
    super.key,
    required this.userInfo,
    this.onAvatarUpload,
    this.isAvatarUploading = false,
    this.onNicknameConfirm,
  });

  @override
  State<AccountContentView> createState() => _AccountContentViewState();
}

class _AccountContentViewState extends State<AccountContentView> {
  @override
  Widget build(BuildContext context) {
    final user = widget.userInfo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                UserAvatarView(
                    onTap: widget.onAvatarUpload,
                    avatar: user.avatar,
                    isLoading: widget.isAvatarUploading),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NicknameEditorView(
                        nickname: user.nickname,
                        displayText: user.nickname.isNotEmpty
                            ? user.nickname
                            : user.email,
                        onConfirm: (newNickname) async {
                          await widget.onNicknameConfirm?.call(newNickname);
                        },
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
                      if (user.createTime != 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '注册于 ${FormatTimeUtil.formatDate(user.createTime)}',
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
            const BackgroundGridSection()
          ],
        ),
      ),
    );
  }
}

/// 背景图网格选择区块。
class BackgroundGridSection extends ConsumerStatefulWidget {
  const BackgroundGridSection({super.key});

  @override
  ConsumerState<BackgroundGridSection> createState() =>
      _BackgroundGridSectionState();
}

class _BackgroundGridSectionState extends ConsumerState<BackgroundGridSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;
  bool _isRefreshing = false;
  int? _loadingItemId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _selectBackground(int? backgroundId) async {
    setState(() => _loadingItemId = backgroundId);
    final error = await ref
        .read(currentUserInfoProvider.notifier)
        .updateBackground(backgroundId);
    if (!mounted) return;
    setState(() => _loadingItemId = null);
    if (error != null) {
      NotificationToast.show('提示', error);
      return;
    }
    NotificationToast.show('提示', backgroundId != null ? '背景图已更新' : '背景图已清除');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.wallpaper_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '更换背景图',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        Consumer(builder: (context, ref, child) {
          final listAsync = ref.watch(backgroundImageListProvider);
          final selectedId = ref.watch(currentUserBackgroundIdProvider) ?? -1;
          return SizeTransition(
            sizeFactor: _expandAnimation,
            alignment: Alignment.topCenter,
            child: listAsync.when(
              data: (list) => _buildGrid(list, selectedId),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '加载背景图失败',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGrid(List<BackgroundImageItem> list, int selectedId) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount =
              (constraints.maxWidth / 180).floor().clamp(2, 4);
          return SizedBox(
            height: 300,
            child: list.isEmpty
                ? Center(
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '什么都没有0_O',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      IconButton(
                        onPressed: _isRefreshing
                            ? null
                            : () {
                                setState(() => _isRefreshing = true);
                                ref
                                    .refresh(backgroundImageListProvider.future)
                                    .whenComplete(() {
                                  if (mounted) {
                                    setState(() => _isRefreshing = false);
                                  }
                                });
                              },
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_outlined),
                        tooltip: '刷新',
                      ),
                    ],
                  ))
                : GridView.builder(
                    padding: const EdgeInsets.all(5),
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 16 / 9,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final isSelected = item.id == selectedId;
                      return GestureDetector(
                        onTap: () => _selectBackground(item.id),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2.5,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  )
                                : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              AnimationNetworkImage(
                                url: item.image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (_loadingItemId == item.id)
                                Container(
                                  color: Colors.black38,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                )
                              else if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
