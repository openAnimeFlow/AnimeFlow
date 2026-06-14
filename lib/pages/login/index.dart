import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/pages/login/service/login_service.dart';
import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
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
  bool _isSubmitting = false;

  final _loginService = LoginService();

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _loginService.login(
        email: _accountController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ref.invalidate(currentFlowTokenProvider);
      ref.invalidate(isLoggedInProvider);
      ref.invalidate(currentUserInfoProvider);
      NotificationToast.show('提示', '登录成功');
      const MainRoute(tab: 2).go(context);
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.message);
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('登录'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, padding.top, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - padding.top - 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            AssetsPathConstants.purpleCatGirlChibi,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.48),
                          ),
                        ),
                        child: _LoginFormPane(form: _buildForm()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
          Text.rich(TextSpan(
            children: [
              TextSpan(
                text: '欢迎来到 ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: '登录后进行收藏管理',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          )),
          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              context,
              label: '邮箱',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              final account = value?.trim() ?? '';
              if (account.isEmpty) return '请输入邮箱';
              if (!account.contains('@')) return '请输入有效邮箱';
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
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_outlined),
            label: Text(_isSubmitting ? '登录中...' : '登录'),
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
              ref.read(userControllerProvider.notifier).openOAuthPage();
            },
            icon: SvgPicture.asset(
              AssetsPathConstants.bangumi,
              height: 20,
              width: 20,
            ),
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
