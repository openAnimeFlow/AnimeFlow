import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:flutter/material.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.onSubmit});

  final Future<void> Function({
    required String oldPassword,
    required String newPassword,
  }) onSubmit;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = resolveAnimeFlowErrorMessage(
          error,
          fallback: l10n.passwordChangeFailed,
        );
      });
      return;
    }
    if (!mounted) return;
    // 先解除 PopScope 的提交保护，再关闭弹窗。
    setState(() => _isSubmitting = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  String? _validatePassword(String? value, String emptyMessage) {
    final password = value ?? '';
    if (password.trim().isEmpty) return emptyMessage;
    if (password.length < 6 || password.length > 30) {
      return AppLocalizations.of(context).passwordLengthRange;
    }
    return null;
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
    bool isLast = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isLast ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: _isSubmitting ? null : onToggle,
          tooltip: obscure ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text(l10n.changePassword),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.changePasswordDescription),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _oldPassword,
                    label: l10n.oldPassword,
                    obscure: _obscureOld,
                    onToggle: () => setState(() => _obscureOld = !_obscureOld),
                    validator: (value) =>
                        _validatePassword(value, l10n.enterOldPassword),
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _newPassword,
                    label: l10n.newPassword,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (value) =>
                        _validatePassword(value, l10n.enterNewPassword),
                  ),
                  const SizedBox(height: 16),
                  _passwordField(
                    controller: _confirmPassword,
                    label: l10n.confirmNewPassword,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    isLast: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterConfirmNewPassword;
                      }
                      if (value != _newPassword.text) {
                        return l10n.passwordMismatch;
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _isSubmitting ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
