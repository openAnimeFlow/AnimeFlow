import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'player_capabilities.dart';
import 'player_event.dart';
import 'player_kernel.dart';
import 'playback_source.dart';

abstract interface class PlayerEngine {
  PlayerKernel get kernel;
  PlayerCapabilities get capabilities;
  Stream<PlayerEvent> get events;

  Widget buildVideoSurface({required BoxFit fit});

  Future<void> initialize();
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<Uint8List?> screenshot();
  Future<void> setShaders(String shaderList);
  Future<void> dispose();
}
