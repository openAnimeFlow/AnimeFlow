import 'dart:async';

import 'package:anime_flow/utils/systemUtil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// 网络图标
class NetworkIcon extends StatefulWidget {
  final double? size;
  final Color? color;

  const NetworkIcon({
    super.key,
    this.size = 16,
    this.color,
  });

  @override
  State<NetworkIcon> createState() => _NetworkIconState();
}

class _NetworkIconState extends State<NetworkIcon> {
  String _networkType = 'unknown';
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _updateNetworkInfo();
    _networkSubscription = SystemUtil.networkStateStream.listen((_) {
      _updateNetworkInfo();
    });
  }

  Future<void> _updateNetworkInfo() async {
    final networkType = await SystemUtil.getNetworkType();
    if (mounted) {
      setState(() {
        _networkType = networkType;
      });
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? Colors.white;

    if (_networkType == SystemUtil.networkTypeWifi) {
      return Icon(
        Icons.wifi,
        size: widget.size,
        color: iconColor,
      );
    } else if (_networkType == SystemUtil.networkTypeMobile) {
      return Icon(
        Icons.signal_cellular_alt,
        size: widget.size,
        color: iconColor,
      );
    } else if (_networkType == SystemUtil.networkTypeEthernet) {
      return Icon(
        Icons.cable,
        size: widget.size,
        color: iconColor,
      );
    } else {
      return Icon(
        Icons.signal_cellular_off,
        size: widget.size,
        color: iconColor.withValues(alpha: 0.5),
      );
    }
  }
}
