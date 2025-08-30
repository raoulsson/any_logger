import '../any_logger.dart';

/// A mixin that provides comprehensive logging capabilities to any Dart class.
///
/// This mixin offers a clean, performant way to add logging to your classes
/// without inheritance. It includes automatic logger caching, performance
/// optimizations with early exit checks, and convenient methods for all log levels.
///
/// ## Basic Usage
///
/// ```dart
/// class PaymentService with AnyLogger {
///   @override
///   String get loggerName => 'PaymentService';
///
///   void processPayment(double amount) {
///     logInfo('Processing payment of \$$amount');
///
///     try {
///       // Payment logic here
///       logDebug('Payment validated');
///     } catch (e) {
///       logError('Payment failed', exception: e);
///     }
///   }
/// }
/// ```
///
/// ## Performance Features
///
/// The mixin includes several performance optimizations:
/// - Logger instances are cached by name, not by object instance (prevents memory leaks)
/// - Early exit checks prevent message formatting if the level is disabled
/// - Supplier methods for lazy evaluation of expensive messages
///
/// ## Using Supplier Methods
///
/// For expensive message creation, use supplier methods to defer evaluation:
///
/// ```dart
/// // ❌ Bad - always computes even if debug is disabled
/// logDebug(expensiveComputation());
///
/// // ✅ Good - only computes if debug is enabled
/// logDebugSupplier(() => expensiveComputation());
/// ```
mixin AnyLogger {
  /// Override this getter to provide a custom logger name for your class.
  ///
  /// The logger name is used for:
  /// - Filtering logs by source
  /// - Identifying the origin of log messages
  /// - Configuring different log levels for different components
  ///
  /// If not overridden, uses the root logger which captures all logs.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// String get loggerName => 'DatabaseService';
  /// ```
  String get loggerName => LoggerFactory.ROOT_LOGGER;

  /// Internal cache of logger instances indexed by logger name.
  ///
  /// This is a static cache shared across all instances to:
  /// - Avoid creating duplicate loggers for the same name
  /// - Prevent memory leaks from instance-based caching
  /// - Improve performance by reusing logger instances
  static final Map<String, Logger> _loggerNameCache = {};

  /// Returns the cached logger instance for this class.
  ///
  /// The logger is cached by name (not by instance) to prevent memory leaks
  /// and ensure consistent behavior across all instances of the same class.
  ///
  /// This is automatically called by all logging methods, so you typically
  /// don't need to access it directly unless you need the underlying Logger.
  Logger get logger {
    return _loggerNameCache.putIfAbsent(loggerName, () => LoggerFactory.getLogger(loggerName));
  }

  /// Clears the internal logger cache.
  ///
  /// This is automatically called by LoggerFactory.dispose() to ensure
  /// proper cleanup. You typically don't need to call this directly.
  static void clearCache() {
    _loggerNameCache.clear();
  }

  /// Returns the active logger name for this instance.
  ///
  /// Useful for debugging or when you need to know which logger
  /// is being used by a particular object.
  String getActiveLoggerName() {
    return loggerName;
  }

  // Performance Check Properties
  // -----------------------------
  // These getters allow you to check if a log level is enabled before
  // doing expensive operations. Use these for performance-critical code.

  /// Returns true if TRACE level logging is enabled.
  ///
  /// Use this before expensive trace logging operations:
  /// ```dart
  /// if (isTraceEnabled) {
  ///   logTrace('Detailed state: ${_captureFullState()}');
  /// }
  /// ```
  bool get isTraceEnabled => logger.isTraceEnabled;

  /// Returns true if DEBUG level logging is enabled.
  ///
  /// Use this to conditionally execute debug code:
  /// ```dart
  /// if (isDebugEnabled) {
  ///   final debugInfo = _gatherDebugInfo();
  ///   logDebug('Debug info: $debugInfo');
  /// }
  /// ```
  bool get isDebugEnabled => logger.isDebugEnabled;

  /// Returns true if INFO level logging is enabled.
  bool get isInfoEnabled => logger.isInfoEnabled;

  /// Returns true if WARN level logging is enabled.
  bool get isWarnEnabled => logger.isWarnEnabled;

  /// Returns true if ERROR level logging is enabled.
  bool get isErrorEnabled => logger.isErrorEnabled;

  /// Returns true if FATAL level logging is enabled.
  bool get isFatalEnabled => logger.isFatalEnabled;

  // Standard Logging Methods
  // ------------------------
  // These methods include early exit checks for performance.
  // If the log level is disabled, the method returns immediately
  // without formatting the message or calling appenders.

  /// Logs a TRACE level message (most detailed logging level).
  ///
  /// TRACE is typically used for:
  /// - Method entry/exit logging
  /// - Detailed state changes
  /// - Loop iterations in algorithms
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  /// - [object]: Deprecated - for backwards compatibility only
  void logTrace(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isTraceEnabled) return;

    logger.logTrace(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a DEBUG level message.
  ///
  /// DEBUG is typically used for:
  /// - Detailed diagnostic information
  /// - Variable values during execution
  /// - Information useful during development
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  void logDebug(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isDebugEnabled) return;

    logger.logDebug(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs an INFO level message.
  ///
  /// INFO is typically used for:
  /// - Important business events
  /// - User actions
  /// - System state changes
  /// - Configuration values at startup
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  void logInfo(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isInfoEnabled) return;

    logger.logInfo(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a WARN level message.
  ///
  /// WARN is typically used for:
  /// - Recoverable errors
  /// - Performance issues
  /// - Deprecated feature usage
  /// - Missing optional configuration
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  void logWarn(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isWarnEnabled) return;

    logger.logWarn(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs an ERROR level message.
  ///
  /// ERROR is typically used for:
  /// - Errors that need attention
  /// - Failed operations
  /// - Unexpected exceptions
  /// - Service failures
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  void logError(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isErrorEnabled) return;

    logger.logError(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a FATAL level message (most severe).
  ///
  /// FATAL is typically used for:
  /// - Unrecoverable errors
  /// - System crashes
  /// - Data corruption
  /// - Security breaches
  ///
  /// Parameters:
  /// - [message]: The log message
  /// - [tag]: Optional tag for categorizing logs
  /// - [exception]: Optional exception object
  /// - [stackTrace]: Optional stack trace
  void logFatal(String message, {String? tag, Object? exception, StackTrace? stackTrace, Object? object}) {
    // Early exit check for performance
    if (!isFatalEnabled) return;

    logger.logFatal(message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  // Supplier Methods (Lazy Evaluation)
  // -----------------------------------
  // These methods accept a function that returns a message string.
  // The function is only called if the log level is enabled,
  // preventing expensive message creation when logs would be discarded.

  /// Logs a TRACE message using lazy evaluation.
  ///
  /// The message supplier function is only called if TRACE is enabled,
  /// avoiding expensive computations for disabled log levels.
  ///
  /// Example:
  /// ```dart
  /// logTraceSupplier(() => 'State: ${_captureExpensiveState()}');
  /// ```
  void logTraceSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isTraceEnabled) return;
    logger.logTrace(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a DEBUG message using lazy evaluation.
  ///
  /// Example:
  /// ```dart
  /// logDebugSupplier(() => 'Cache stats: ${_computeCacheStats()}');
  /// ```
  void logDebugSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isDebugEnabled) return;
    logger.logDebug(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs an INFO message using lazy evaluation.
  ///
  /// Example:
  /// ```dart
  /// logInfoSupplier(() => 'Processed ${_countRecords()} records');
  /// ```
  void logInfoSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isInfoEnabled) return;
    logger.logInfo(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a WARN message using lazy evaluation.
  ///
  /// Example:
  /// ```dart
  /// logWarnSupplier(() => 'Queue size: ${_getQueueMetrics()}');
  /// ```
  void logWarnSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isWarnEnabled) return;
    logger.logWarn(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs an ERROR message using lazy evaluation.
  ///
  /// Example:
  /// ```dart
  /// logErrorSupplier(() => 'Failed after ${_getRetryCount()} retries');
  /// ```
  void logErrorSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isErrorEnabled) return;
    logger.logError(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Logs a FATAL message using lazy evaluation.
  ///
  /// Example:
  /// ```dart
  /// logFatalSupplier(() => 'System state: ${_dumpSystemState()}');
  /// ```
  void logFatalSupplier(String Function() messageSupplier, {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isFatalEnabled) return;
    logger.logFatal(messageSupplier(), tag: tag, exception: exception, stackTrace: stackTrace);
  }
}
