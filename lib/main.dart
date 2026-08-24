import 'dart:async';
import 'package:anime_flow/core/logger/logger.dart';
import 'app/bootstrap.dart';

void main() {
  runZonedGuarded(
    () => bootstrap(),
    (error, stackTrace) {
      LiggLogger().f(
        'Unhandled zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
