import 'package:anime_flow/controllers/shaders/shaders_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 初始化着色器资源并暴露 [ShadersController]（全应用单例）。
final shadersControllerProvider = FutureProvider<ShadersController>((ref) async {
  ref.keepAlive();
  final c = ShadersController();
  await c.copyShadersToExternalDirectory();
  return c;
});
