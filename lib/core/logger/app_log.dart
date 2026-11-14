import 'dart:developer' as developer;

typedef LogMessage = void Function(Object? message,
    {Object? error, StackTrace? stackTrace});

// 应用启动时将这两个入口接到 LiggLogger。独立运行的 isolate 使用 Dart 日志。
LogMessage logWarning = _developerLog(900);
LogMessage logError = _developerLog(1000);

LogMessage _developerLog(int level) => (message, {error, stackTrace}) {
      developer.log('$message',
          name: 'AnimeFlow',
          level: level,
          error: error,
          stackTrace: stackTrace);
    };
