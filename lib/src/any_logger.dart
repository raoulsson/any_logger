import '../any_logger_lib.dart';

/// Mixin for logging capabilities that can be customized with a logger name
mixin AnyLogger {
  /// Override this in your class to use a specific named logger
  String get loggerName => LoggerFactory.ROOT_LOGGER;

  /// Get the logger for this class
  Logger get logger => LoggerFactory.getLogger(loggerName);

  String getActiveLoggerName() {
    return loggerName;
  }

  void logTrace(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logTrace(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logDebug(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logDebug(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logInfo(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logInfo(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logWarn(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logWarn(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logError(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logError(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logFatal(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    logger.logFatal(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }
}
