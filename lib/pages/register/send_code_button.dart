import 'dart:async';

import 'package:flutter/material.dart';

class SendCodeButton extends StatefulWidget {
  const SendCodeButton({
    super.key,
    required this.onSend,
    this.width = 120,
  });

  final Future<bool> Function() onSend;
  final double width;

  @override
  State<SendCodeButton> createState() => _SendCodeButtonState();
}

class _SendCodeButtonState extends State<SendCodeButton> {
  bool _isSending = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _handlePress() async {
    if (_isSending || _countdown > 0) return;

    setState(() => _isSending = true);
    try {
      final success = await widget.onSend();
      if (!mounted) return;
      if (success) _startCountdown();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: widget.width,
      child: OutlinedButton(
        onPressed: (_isSending || _countdown > 0) ? null : _handlePress,
        child: _isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(
                _countdown > 0 ? '${_countdown}s' : '发送验证码',
                style: const TextStyle(fontSize: 13),
              ),
      ),
    );
  }
}
