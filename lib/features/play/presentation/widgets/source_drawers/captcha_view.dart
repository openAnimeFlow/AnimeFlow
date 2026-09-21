import 'dart:async';
import 'dart:convert';

import 'package:anime_flow/core/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/features/play/presentation/providers/captcha_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';

/// 验证码 UI。
class CaptchaView extends StatefulWidget {
  const CaptchaView({
    super.key,
    required this.resource,
    required this.dataSourceController,
    required this.subjectName,
    this.isBottomSheet = false,
  });

  final ResourcesItem resource;
  final VideoSourceNotifier dataSourceController;
  final String subjectName;
  final bool isBottomSheet;

  @override
  State<CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<CaptchaView> {
  CaptchaProvider? _provider;
  Timer? _verifyTimer;
  StreamSubscription? _imageSub;
  final _codeController = TextEditingController();
  String? _imageData;
  bool _sessionActive = false;
  bool _isSubmitting = false;
  bool _isAutoVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    _disposeSession();
    super.dispose();
  }

  void _disposeSession() {
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    _provider?.dispose();
    _provider = null;
    _sessionActive = false;
    _isSubmitting = false;
    _isAutoVerifying = false;
    _imageData = null;
  }

  void _startVerification() {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null) return;
    final keyword = widget.subjectName;

    _disposeSession();
    _provider = CaptchaProvider();
    final name = widget.resource.websiteName;
    final url = widget.resource.searchUrl.replaceFirst(
      '{keyword}',
      Uri.encodeQueryComponent(keyword),
    );

    if (config.captchaType == CaptchaType.autoClickButton) {
      setState(() {
        _sessionActive = true;
        _isAutoVerifying = true;
      });
      _provider!.loadForButtonClick(
        url: url,
        buttonXpath: config.captchaButton,
        pluginName: name,
        onVerified: () => _onVerified(name),
      );
    } else {
      setState(() {
        _sessionActive = true;
        _imageData = null;
        _isSubmitting = false;
      });

      _imageSub = _provider!.onCaptchaImageUrl.listen((imageUrl) {
        if (imageUrl != null && mounted) {
          setState(() {
            _imageData = imageUrl;
            if (_isSubmitting) {
              _isSubmitting = false;
              _codeController.clear();
              _verifyTimer?.cancel();
              _verifyTimer = null;
            }
          });
        }
      });

      _provider!.loadForCaptcha(
        url,
        config.captchaImage,
        inputXpath: config.captchaInput,
      );
    }
  }

  void _onVerified(String websiteName) {
    if (!mounted) return;
    final dataSourceController = widget.dataSourceController;
    _disposeSession();
    dataSourceController.markCaptchaVerified(websiteName);
    setState(() {});
    Future<void>.delayed(const Duration(seconds: 3), () {
      dataSourceController.retryResources(websiteName);
    });
  }

  Future<void> _submit() async {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null || _isSubmitting) return;
    if (_codeController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context);
      _showToast(l10n.enterCaptcha, l10n.tip);
      return;
    }
    setState(() => _isSubmitting = true);
    final name = widget.resource.websiteName;

    await _provider?.submitCaptcha(
      captchaCode: _codeController.text.trim(),
      inputXpath: config.captchaInput,
      buttonXpath: config.captchaButton,
      pluginName: name,
      onVerified: () => _onVerified(name),
    );

    if (_sessionActive && mounted) {
      _verifyTimer?.cancel();
      _verifyTimer = Timer(const Duration(seconds: 8), () async {
        if (!_sessionActive || !mounted) return;
        setState(() {
          _isSubmitting = false;
          _codeController.clear();
        });
        final l10n = AppLocalizations.of(context);
        _showToast(l10n.captchaMayBeWrong, l10n.tip);
        await _reloadCaptchaImage();
      });
    }
  }

  void _showToast(String message, String title) {
    NotificationToast.show(message, title: title);
  }

  Future<void> _reloadCaptchaImage() async {
    final config = widget.resource.antiCrawlerConfig;
    final provider = _provider;
    if (config == null ||
        provider == null ||
        !_sessionActive ||
        _isAutoVerifying) {
      return;
    }
    _verifyTimer?.cancel();
    _verifyTimer = null;
    if (!mounted) return;
    setState(() {
      _imageData = null;
      _isSubmitting = false;
    });
    await provider.reloadCaptchaImage(
      config.captchaImage,
      inputXpath: config.captchaInput,
    );
  }

  void _cancel() {
    final name = widget.resource.websiteName;
    final provider = _provider;
    _provider = null;
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    setState(() {
      _sessionActive = false;
      _isSubmitting = false;
      _isAutoVerifying = false;
      _imageData = null;
      _codeController.clear();
    });
    provider?.saveAndUnload(name).then((_) {
      provider.dispose();
      widget.dataSourceController.retryResources(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    final l10n = AppLocalizations.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final compact = widget.isBottomSheet && keyboardInset > 0;

    if (!_sessionActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.siteRequiresCaptcha(resource.websiteName),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _startVerification,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(l10n.verify),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.dataSourceController
                      .retryResources(resource.websiteName),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isAutoVerifying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.siteAutoVerifying(resource.websiteName),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancel,
              child: Text(l10n.cancel,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: widget.isBottomSheet ? 0 : keyboardInset),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Icon(Icons.shield_outlined,
                      size: 36, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(l10n.captchaVerification(resource.websiteName),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 16),
                ],
                if (_imageData == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.loadingCaptchaImage),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: (_isSubmitting || _imageData == null)
                          ? null
                          : () {
                              _codeController.clear();
                              _reloadCaptchaImage();
                            },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: compact ? 100 : double.infinity,
                        ),
                        child: Image.memory(
                          width: double.infinity,
                          base64Decode(_imageData!.split(',').last),
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, _) =>
                              Text(l10n.imageDecodeFailed),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: l10n.enterCaptcha,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: _isSubmitting ? null : (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancel,
                        child: Text(l10n.cancel,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: (_imageData == null || _isSubmitting)
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(l10n.submit),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
