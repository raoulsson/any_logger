import '../any_logger_lib.dart';
import 'logger_factory.dart';

/// Mixin for logging capabilities that can be customized with a logger name
mixin AnyLogger {
  /// Override this in your class to use a specific named logger
  String get loggerName => 'ROOT';

  /// Get the logger for this class
  Logger get _logger => LoggerFactory.getLogger(loggerName);

  void logTrace(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logTrace(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logDebug(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logDebug(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logInfo(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logInfo(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logWarn(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logWarn(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logError(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logError(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logFatal(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    _logger.logFatal(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }
}