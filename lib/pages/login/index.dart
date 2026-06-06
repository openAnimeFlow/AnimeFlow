import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/features/my/my_controller_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('账号密码登录接口待接入')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号登录'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child:  SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isWide) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        AssetsPathConstants.purpleCatGirlChibi,
                        height: 168,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.48),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: isWide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _LoginVisualPane(theme: theme)),
                                Expanded(
                                  child: _LoginFormPane(form: _buildForm()),
                                ),
                              ],
                            ),
                          )
                        : Column(
                          children: [
                            _LoginVisualPane(theme: theme, compact: true),
                            _LoginFormPane(form: _buildForm()),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '欢迎回来',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              context,
              label: '邮箱 / 用户名',
              icon: Icons.person_outline,
            ),
            validator: (value) {
              final account = value?.trim() ?? '';
              if (account.isEmpty) return '请输入邮箱或用户名';
              if (account.length < 3) return '账号至少需要 3 个字符';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: _inputDecoration(
              context,
              label: '密码',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) return '请输入密码';
              if (password.length < 6) return '密码至少需要 6 位';
              return null;
            },
          ),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
              ),
              const Text('记住登录'),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('忘记密码'),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.login_outlined),
            label: const Text('登录'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(myControllerProvider).openOAuthPage();
            },
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text('Bangumi 授权登录'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '还没有账号？',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('立即注册'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    );
  }
}

class _LoginVisualPane extends StatelessWidget {
  const _LoginVisualPane({
    required this.theme,
    this.compact = false,
  });

  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.fromLTRB(24, compact ? 22 : 34, 24, compact ? 18 : 34),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: compact
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : const BorderRadius.horizontal(left: Radius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Image.asset(
            AssetsPathConstants.logo,
            width: compact ? 96 : 128,
            height: compact ? 96 : 128,
            fit: BoxFit.contain,
          ),
          Text(
            'AnimeFlow',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '登录后继续管理收藏、播放记录与追番进度',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '使用 AnimeFlow 账号继续同步你的追番记录',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormPane extends StatelessWidget {
  const _LoginFormPane({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: form,
    );
  }
}
