import 'dart:async';

import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/pages/register/graphic_captcha.dart';
import 'package:anime_flow/pages/register/send_code_button.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _graphicCaptchaController = GraphicCaptchaController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    _graphicCaptchaController.dispose();
    super.dispose();
  }

  Future<bool> _sendEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NotificationToast.show('提示', '请先填写有效邮箱');
      return false;
    }
    if (!_graphicCaptchaController.isReady) {
      NotificationToast.show('提示', '请先填写图形验证码');
      return false;
    }

    try {
      await FlowRequest.sendEmailCodeService(
        email: email,
        captchaId: _graphicCaptchaController.captchaId!,
        captcha: _graphicCaptchaController.text,
      );
      if (!mounted) return false;
      NotificationToast.show('提示', '验证码已发送，请查收邮件');
      unawaited(_graphicCaptchaController.reload());
      return true;
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return false;
      NotificationToast.show('提示', e.message);
      unawaited(_graphicCaptchaController.reload());
      return false;
    } catch (e) {
      if (!mounted) return false;
      NotificationToast.show('提示', e.toString());
      unawaited(_graphicCaptchaController.reload());
      return false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await FlowRequest.forgotPasswordService(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailCaptcha: _emailCodeController.text.trim(),
      );
      if (!mounted) return;
      NotificationToast.show('提示', '密码重置成功，请使用新密码登录');
      context.pop();
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

    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        title: const Text('忘记密码'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            10, topPadding + kToolbarHeight, 10, bottomPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 120,
                    width: 160,
                    child: Image.asset(
                      AssetsPathConstants.purpleCatGirlChibi,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Material(
                  elevation: 1,
                  shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '重置密码',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '通过邮箱验证码重置登录密码，每个邮箱每天仅可重置一次',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: '邮箱',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return '请输入邮箱';
                              if (!email.contains('@')) {
                                return '邮箱格式不正确';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: '新密码',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) return '请输入新密码';
                              if (password.length < 6 || password.length > 30) {
                                return '密码长度需在 6-30 位之间';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: '确认新密码',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return '请再次输入新密码';
                              }
                              if (value != _passwordController.text) {
                                return '两次输入的密码不一致';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          GraphicCaptchaView(
                            controller: _graphicCaptchaController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCodeController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: const InputDecoration(
                                    labelText: '邮箱验证码',
                                    prefixIcon:
                                        Icon(Icons.mark_email_read_outlined),
                                  ),
                                  validator: (value) {
                                    final code = value?.trim() ?? '';
                                    if (code.isEmpty) {
                                      return '请输入邮箱验证码';
                                    }
                                    if (code.length != 6) {
                                      return '验证码为 6 位数字';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SendCodeButton(onSend: _sendEmailCode),
                            ],
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    '重置密码',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('返回登录'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
