import 'package:anime_flow/utils/network_util.dart';
import 'package:flutter/material.dart';

class NetworkCheckButton extends StatefulWidget {
  const NetworkCheckButton({
    super.key,
    required this.url,
    this.label,
    this.successTitle,
    this.failureTitle,
    this.successHint,
    this.failureHint,
  });

  final String url;
  final String? label;
  final String? successTitle;
  final String? failureTitle;
  final String? successHint;
  final String? failureHint;

  @override
  State<NetworkCheckButton> createState() => _NetworkCheckButtonState();
}

class _NetworkCheckButtonState extends State<NetworkCheckButton> {
  bool _checking = false;
  bool? _reachable;

  String get _displayLabel {
    if (widget.label != null && widget.label!.isNotEmpty) {
      return widget.label!;
    }
    final host = Uri.tryParse(widget.url)?.host;
    return host != null && host.isNotEmpty ? host : widget.url;
  }

  @override
  void initState() {
    super.initState();
    _checkNetwork(showResultDialog: false);
  }

  Future<void> _checkNetwork({required bool showResultDialog}) async {
    if (_checking) return;

    setState(() => _checking = true);
    try {
      final result = await NetworkUtil.checkReachability(url: widget.url);
      if (!mounted) return;

      setState(() => _reachable = result.reachable);

      if (!showResultDialog) return;

      final buffer = StringBuffer();
      if (result.reachable) {
        buffer.write(
          '当前网络可以正常访问 ${widget.url}（${result.latencyMs} ms）。',
        );
        if (widget.successHint != null && widget.successHint!.isNotEmpty) {
          buffer.write('\n\n${widget.successHint}');
        }
      } else {
        buffer.write('当前网络无法访问 ${widget.url}。');
        if (result.message != null && result.message!.isNotEmpty) {
          buffer.write('\n\n${result.message}');
        }
        if (widget.failureHint != null && widget.failureHint!.isNotEmpty) {
          buffer.write('\n\n${widget.failureHint}');
        }
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            result.reachable
                ? (widget.successTitle ?? '网络正常')
                : (widget.failureTitle ?? '无法访问 $_displayLabel'),
          ),
          content: Text(buffer.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Color _statusDotColor(ColorScheme colorScheme) {
    if (_checking || _reachable == null) {
      return colorScheme.outline;
    }
    return _reachable! ? Colors.green : colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: '检测 $_displayLabel 网络',
          visualDensity: VisualDensity.compact,
          onPressed: _checking
              ? null
              : () => _checkNetwork(showResultDialog: true),
          icon: _checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check_outlined, size: 22),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusDotColor(colorScheme),
          ),
        ),
      ],
    );
  }
}
