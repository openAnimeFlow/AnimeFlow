import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/auth/presentation/widgets/send_code_button.dart';
import 'package:anime_flow/features/auth/presentation/widgets/graphic_captcha.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
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
    final l10n = AppLocalizations.of(context);
    if (email.isEmpty || !email.contains('@')) {
      NotificationToast.show(l10n.invalidEmail, title: l10n.tip);
      return false;
    }
    if (!_graphicCaptchaController.isReady) {
      NotificationToast.show(l10n.enterGraphicCaptcha, title: l10n.tip);
      return false;
    }

    try {
      await FlowApi.sendEmailCodeService(
        email: email,
        captchaId: _graphicCaptchaController.captchaId!,
        captcha: _graphicCaptchaController.text,
      );
      if (!mounted) return false;
      NotificationToast.show(l10n.emailCodeSent, title: l10n.tip);
      // 图形验证码校验成功后服务端会删除，需刷新以便再次发送
      unawaited(_graphicCaptchaController.reload());
      return true;
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return false;
      NotificationToast.show(e.message, title: '提示');
      unawaited(_graphicCaptchaController.reload());
      return false;
    } catch (e) {
      if (!mounted) return false;
      NotificationToast.show(e.toString(), title: '提示');
      unawaited(_graphicCaptchaController.reload());
      return false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _isSubmitting = true);
    try {
      await FlowApi.registerService(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailCaptcha: _emailCodeController.text.trim(),
      );
      if (!mounted) return;
      NotificationToast.show(l10n.registerSuccess, title: l10n.tip);
      context.pop();
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.message, title: '提示');
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.toString(), title: '提示');
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
    final l10n = AppLocalizations.of(context);

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
        title: Text(l10n.registerTitle),
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
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.createAccount,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.registerSubtitle,
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
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return l10n.enterEmail;
                                  if (!email.contains('@')) {
                                    return l10n.invalidEmailFormat;
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
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                                  if (password.isEmpty) {
                                    return l10n.enterPassword;
                                  }
                                  if (password.length < 6 ||
                                      password.length > 30) {
                                    return l10n.passwordLengthRange;
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
                                  labelText: l10n.confirmPassword,
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
                                    return l10n.enterConfirmPassword;
                                  }
                                  if (value != _passwordController.text) {
                                    return l10n.passwordMismatch;
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailCodeController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        labelText: l10n.emailVerificationCode,
                                        prefixIcon: const Icon(
                                            Icons.mark_email_read_outlined),
                                      ),
                                      validator: (value) {
                                        final code = value?.trim() ?? '';
                                        if (code.isEmpty) {
                                          return l10n.enterEmailCode;
                                        }
                                        if (code.length != 6) {
                                          return l10n.emailCodeLength;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SendCodeButton(onSend: _sendEmailCode),
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
                                    : Text(
                                        l10n.registerAccount,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: Text(l10n.haveAccountBackToLogin),
                              ),
                            ],
                          ),
                        ),
                      ],
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
