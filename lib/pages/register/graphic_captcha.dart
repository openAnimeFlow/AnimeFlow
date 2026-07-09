import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/models/item/captcha_item.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';

class GraphicCaptchaController {
  CaptchaItem? captcha;
  final TextEditingController textController = TextEditingController();

  Future<void> Function()? _reload;

  String? get captchaId => captcha?.captchaId;
  String get text => textController.text.trim();
  bool get isReady => captcha != null && text.isNotEmpty;

  void _bindReload(Future<void> Function() reload) {
    _reload = reload;
  }

  Future<void> reload() async {
    await _reload?.call();
  }

  void dispose() {
    textController.dispose();
  }
}

class GraphicCaptchaView extends StatefulWidget {
  const GraphicCaptchaView({
    super.key,
    required this.controller,
  });

  final GraphicCaptchaController controller;

  @override
  State<GraphicCaptchaView> createState() => _GraphicCaptchaViewState();
}

class _GraphicCaptchaViewState extends State<GraphicCaptchaView> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.controller._bindReload(_loadCaptcha);
    unawaited(_loadCaptcha());
  }

  Future<void> _loadCaptcha() async {
    if (_isLoading) return;

    final previousCaptchaId = widget.controller.captcha?.captchaId;
    setState(() => _isLoading = true);
    try {
      final captcha = await FlowRequest.generateCaptchaService(
        captchaId: previousCaptchaId,
      );
      if (!mounted) return;
      setState(() {
        widget.controller.captcha = captcha;
        widget.controller.textController.clear();
      });
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.toString());
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show('提示', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Uint8List? _decodeCaptchaImage(String base64Image) {
    try {
      final normalized =
          base64Image.contains(',') ? base64Image.split(',').last : base64Image;
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final captcha = widget.controller.captcha;
    final captchaBytes =
        captcha == null ? null : _decodeCaptchaImage(captcha.imageBase64);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.controller.textController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '输入6位验证码',
              prefixIcon: Icon(Icons.verified_outlined),
            ),
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
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: _isLoading || captchaBytes == null
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
    );
  }
}
