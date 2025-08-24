import '../any_logger_lib.dart';

/// Mixin for logging capabilities that can be customized with a logger name
mixin AnyLogger {
  /// Override this in your class to use a specific named logger
  String get loggerName => LoggerFactory.ROOT_LOGGER;

  // Cache by logger name instead of instance to avoid memory leaks
  static final Map<String, Logger> _loggerNameCache = {};

  /// Get the logger for this class (cached by logger name, not instance)
  Logger get logger {
    // Cache by logger name instead of instance to avoid memory leaks
    return _loggerNameCache.putIfAbsent(loggerName, () => LoggerFactory.getLogger(loggerName));
  }

  /// Clear the internal logger cache - called by LoggerFactory.dispose()
  static void clearCache() {
    _loggerNameCache.clear();
  }

  String getActiveLoggerName() {
    return loggerName;
  }

  /// Check if logging levels are enabled (for performance)
  bool get isTraceEnabled => logger.isTraceEnabled;

  bool get isDebugEnabled => logger.isDebugEnabled;

  bool get isInfoEnabled => logger.isInfoEnabled;

  bool get isWarnEnabled => logger.isWarnEnabled;

  bool get isErrorEnabled => logger.isErrorEnabled;

  bool get isFatalEnabled => logger.isFatalEnabled;

  void logTrace(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isTraceEnabled) return;

    logger.logTrace(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logDebug(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isDebugEnabled) return;

    logger.logDebug(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logInfo(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isInfoEnabled) return;

    logger.logInfo(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logWarn(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isWarnEnabled) return;

    logger.logWarn(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logError(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isErrorEnabled) return;

    logger.logError(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logFatal(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isFatalEnabled) return;

    logger.logFatal(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Use this for expensive message creation
  void logTraceSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isTraceEnabled) return;
    logger.logTrace(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logDebugSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isDebugEnabled) return;
    logger.logDebug(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logInfoSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isInfoEnabled) return;
    logger.logInfo(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logWarnSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isWarnEnabled) return;
    logger.logWarn(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logErrorSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isErrorEnabled) return;
    logger.logError(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logFatalSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isFatalEnabled) return;
    logger.logFatal(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }
}
