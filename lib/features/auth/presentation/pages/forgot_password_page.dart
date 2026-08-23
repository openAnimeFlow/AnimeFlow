import 'dart:async';

import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/auth/presentation/widgets/graphic_captcha.dart';
import 'package:anime_flow/features/auth/presentation/widgets/send_code_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
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
      unawaited(_graphicCaptchaController.reload());
      return true;
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return false;
      NotificationToast.show(e.message, title: l10n.tip);
      unawaited(_graphicCaptchaController.reload());
      return false;
    } catch (e) {
      if (!mounted) return false;
      NotificationToast.show(e.toString(), title: l10n.tip);
      unawaited(_graphicCaptchaController.reload());
      return false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context);
    try {
      await FlowApi.forgotPasswordService(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailCaptcha: _emailCodeController.text.trim(),
      );
      if (!mounted) return;
      NotificationToast.show(l10n.passwordResetSuccess, title: l10n.tip);
      context.pop();
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.message, title: l10n.tip);
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.toString(), title: l10n.tip);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(l10n.forgotPassword),
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
                            l10n.resetPassword,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.resetPasswordDescription,
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
                              prefixIcon: const Icon(Icons.email_outlined),
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
                              labelText: l10n.newPassword,
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
                              if (password.isEmpty) return l10n.enterNewPassword;
                              if (password.length < 6 || password.length > 30) {
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
                              labelText: l10n.confirmNewPassword,
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
                                return l10n.enterConfirmNewPassword;
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCodeController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: l10n.emailCode,
                                    prefixIcon:
                                        const Icon(Icons.mark_email_read_outlined),
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
                                : Text(
                                    l10n.resetPassword,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(l10n.backToLogin),
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
