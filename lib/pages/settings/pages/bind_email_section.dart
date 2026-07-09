import 'dart:async';

import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/network/requests/flow_request.dart';
import 'package:anime_flow/pages/register/graphic_captcha.dart';
import 'package:anime_flow/pages/register/send_code_button.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 账户设置页：未绑定邮箱时展示绑定表单。
class BindEmailSection extends ConsumerStatefulWidget {
  const BindEmailSection({super.key});

  @override
  ConsumerState<BindEmailSection> createState() => _BindEmailSectionState();
}

class _BindEmailSectionState extends ConsumerState<BindEmailSection> {
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
      await FlowRequest.bindEmailService(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailCaptcha: _emailCodeController.text.trim(),
      );
      if (!mounted) return;
      ref.invalidate(currentUserInfoProvider);
      NotificationToast.show('提示', '邮箱绑定成功');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.email_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '绑定邮箱',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '绑定后可使用邮箱密码登录 AnimeFlow',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  prefixIcon: Icon(Icons.email_outlined),
                  isDense: true,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return '请输入邮箱';
                  if (!email.contains('@')) return '邮箱格式不正确';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '登录密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  isDense: true,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                  if (password.length < 6 || password.length > 30) {
                    return '密码长度需在 6-30 位之间';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  isDense: true,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) return '请再次输入密码';
                  if (value != _passwordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GraphicCaptchaView(controller: _graphicCaptchaController),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '邮箱验证码',
                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                        isDense: true,
                      ),
                      validator: (value) {
                        final code = value?.trim() ?? '';
                        if (code.isEmpty) return '请输入邮箱验证码';
                        if (code.length != 6) return '验证码为 6 位';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SendCodeButton(onSend: _sendEmailCode),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('确认绑定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
