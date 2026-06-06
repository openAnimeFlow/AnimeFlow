import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/captcha_item.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _captchaController = TextEditingController();

  CaptchaItem? _captcha;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isSendingCode = false;
  int _codeCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCaptcha());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    try {
      final captcha = await FlowRequest.generateCaptchaService();
      if (!mounted) return;
      setState(() {
        _captcha = captcha;
        _captchaController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.toString());
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _codeCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_codeCountdown <= 1) {
        timer.cancel();
        setState(() => _codeCountdown = 0);
      } else {
        setState(() => _codeCountdown -= 1);
      }
    });
  }

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NotificationToast.show('提示', '请先填写有效邮箱');
      return;
    }
    final captcha = _captchaController.text.trim();
    if (_captcha == null || captcha.isEmpty) {
      NotificationToast.show('提示', '请先填写图形验证码');
      return;
    }
    if (_isSendingCode || _codeCountdown > 0) return;

    setState(() => _isSendingCode = true);
    try {
      await FlowRequest.sendEmailCodeService(
        email: email,
        captchaId: _captcha!.captchaId,
        captcha: captcha,
      );
      if (!mounted) return;
      NotificationToast.show('提示', '验证码已发送，请查收邮件');
      _startCountdown();
      unawaited(_loadCaptcha());
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.message);
      unawaited(_loadCaptcha());
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.toString());
      unawaited(_loadCaptcha());
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await FlowRequest.registerService(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailCode: _emailCodeController.text.trim(),
      );
      if (!mounted) return;
      NotificationToast.show('提示', '注册成功');
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

  Uint8List? _decodeCaptchaImage(String base64Image) {
    try {
      final normalized = base64Image.contains(',')
          ? base64Image.split(',').last
          : base64Image;
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final captchaBytes =
        _captcha == null ? null : _decodeCaptchaImage(_captcha!.imageBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 88),
                    child: Material(
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
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '创建账号',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '加入 AnimeFlow，同步你的追番体验',
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
                                  labelText: '密码',
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
                                  if (password.isEmpty) return '请输入密码';
                                  if (password.length < 6 ||
                                      password.length > 30) {
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
                                  labelText: '确认密码',
                                  prefixIcon:
                                      const Icon(Icons.lock_reset_outlined),
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
                                    return '请再次输入密码';
                                  }
                                  if (value != _passwordController.text) {
                                    return '两次输入的密码不一致';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _captchaController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '输入6位验证码',
                                        prefixIcon:
                                            Icon(Icons.verified_outlined),
                                      ),
                                      validator: (value) {
                                        if ((value ?? '').trim().isEmpty) {
                                          return '请输入图形验证码';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: _loadCaptcha,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 112,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: captchaBytes == null
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                captchaBytes,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
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
                                  SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: (_isSendingCode ||
                                              _codeCountdown > 0)
                                          ? null
                                          : _sendEmailCode,
                                      child: _isSendingCode
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _codeCountdown > 0
                                                  ? '${_codeCountdown}s'
                                                  : '发送验证码',
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              FilledButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                        '注册',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('已有账号？返回登录'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Image.asset(
                      AssetsPathConstants.purpleCatGirlChibi,
                      height: 132,
                      fit: BoxFit.contain,
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
}
