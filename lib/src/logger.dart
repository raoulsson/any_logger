import '../any_logger.dart';

/// Main Logger class with both static and instance methods
class Logger {
  // ============================================================
  // FIELDS
  // ============================================================

  final String name;
  final List<Appender> appenders = [];
  final List<Appender> customAppenders = [];

  int clientDepthOffset = 0;
  String? tag;
  bool enabled = true;

  // Cache the minimum log level across all appenders for quick checks
  Level? _minLevel;
  bool _minLevelDirty = true;

  // ============================================================
  // CONSTRUCTORS
  // ============================================================

  Logger.defaultLogger(
    List<Appender> appendersFromConfig, {
    int clientDepthOffset = 0,
    String? name,
  }) : name = name ?? LoggerFactory.ROOT_LOGGER {
    getSelfLogger()?.logInfo('Creating default logger with name: ${this.name}');
    appenders.addAll(appendersFromConfig);
    this.clientDepthOffset = clientDepthOffset;
    _minLevelDirty = true;

    // Auto-register named loggers (except root logger) for retrieval via LoggerFactory.getLogger()
    if (name != null && name != LoggerFactory.ROOT_LOGGER) {
      LoggerFactory.registerCustomLogger(this);
    }
  }

  Logger.fromExisting(
    Logger other, {
    required String name,
    bool consoleOnly = false,
  })  : name = name,
        clientDepthOffset = other.clientDepthOffset {
    getSelfLogger()?.logInfo(
        'Creating new logger named $name from existing logger: ${other.name}');

    // Create deep copies of appenders
    appenders
        .addAll(other.appenders.map((appender) => appender.createDeepCopy()));

    if (consoleOnly) {
      appenders.removeWhere((appender) => appender.getType() != 'CONSOLE');
    }

    // Same for custom appenders
    customAppenders.addAll(
        other.customAppenders.map((appender) => appender.createDeepCopy()));

    if (consoleOnly) {
      customAppenders
          .removeWhere((appender) => appender.getType() != 'CONSOLE');
    }

    tag = other.tag;
    _minLevelDirty = true;
  }

  Logger.empty() : name = LoggerFactory.ROOT_LOGGER;

  // ============================================================
  // STATIC CONVENIENCE METHODS - For quick logging without instance
  // ============================================================

  static void trace(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logTrace(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void debug(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logDebug(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void info(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logInfo(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void warn(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logWarn(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void error(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logError(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void fatal(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    LoggerFactory.getRootLogger().logFatal(message,
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  /// Static level check methods (use root logger)
  static bool get traceEnabled => LoggerFactory.getRootLogger().isTraceEnabled;

  static bool get debugEnabled => LoggerFactory.getRootLogger().isDebugEnabled;

  static bool get infoEnabled => LoggerFactory.getRootLogger().isInfoEnabled;

  static bool get warnEnabled => LoggerFactory.getRootLogger().isWarnEnabled;

  static bool get errorEnabled => LoggerFactory.getRootLogger().isErrorEnabled;

  static bool get fatalEnabled => LoggerFactory.getRootLogger().isFatalEnabled;

  // ============================================================
  // INSTANCE LEVEL CHECKING - For performance optimization
  // ============================================================

  /// Instance level checking properties
  bool get isTraceEnabled => isLevelEnabled(Level.TRACE);

  bool get isDebugEnabled => isLevelEnabled(Level.DEBUG);

  bool get isInfoEnabled => isLevelEnabled(Level.INFO);

  bool get isWarnEnabled => isLevelEnabled(Level.WARN);

  bool get isErrorEnabled => isLevelEnabled(Level.ERROR);

  bool get isFatalEnabled => isLevelEnabled(Level.FATAL);

  /// Check if a specific level is enabled for this logger
  bool isLevelEnabled(Level level) {
    if (!enabled) return false;
    return level.index >= minLevel.index;
  }

  /// Get the minimum log level across all enabled appenders
  Level get minLevel {
    if (_minLevelDirty) {
      _updateMinLevel();
    }
    return _minLevel ?? Level.FATAL;
  }

  void _updateMinLevel() {
    Level? min;
    for (var appender in appenders) {
      if (appender.enabled) {
        if (min == null || appender.level.index < min.index) {
          min = appender.level;
        }
      }
    }
    for (var appender in customAppenders) {
      if (appender.enabled) {
        if (min == null || appender.level.index < min.index) {
          min = appender.level;
        }
      }
    }
    _minLevel = min;
    _minLevelDirty = false;
  }

  // ============================================================
  // INSTANCE LOGGING METHODS
  // ============================================================

  void logTrace(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if trace won't be logged
    if (!isLevelEnabled(Level.TRACE)) return;

    tag ??= '';
    log(Level.TRACE, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logDebug(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if debug won't be logged
    if (!isLevelEnabled(Level.DEBUG)) return;

    tag ??= '';
    log(Level.DEBUG, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logInfo(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if info won't be logged
    if (!isLevelEnabled(Level.INFO)) return;

    tag ??= '';
    log(Level.INFO, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logWarn(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if warn won't be logged
    if (!isLevelEnabled(Level.WARN)) return;

    tag ??= '';
    log(Level.WARN, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logError(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if error won't be logged
    if (!isLevelEnabled(Level.ERROR)) return;

    tag ??= '';
    log(Level.ERROR, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logFatal(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    // Early exit if fatal won't be logged
    if (!isLevelEnabled(Level.FATAL)) return;

    tag ??= '';
    log(Level.FATAL, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  // ============================================================
  // SUPPLIER METHODS - For expensive message creation
  // ============================================================

  void logTraceSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isTraceEnabled) return;
    logTrace(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logDebugSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isDebugEnabled) return;
    logDebug(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logInfoSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isInfoEnabled) return;
    logInfo(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logWarnSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isWarnEnabled) return;
    logWarn(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logErrorSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isErrorEnabled) return;
    logError(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  void logFatalSupplier(String Function() messageSupplier,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    if (!isFatalEnabled) return;
    logFatal(messageSupplier(),
        tag: tag, exception: exception, stackTrace: stackTrace);
  }

  // ============================================================
  // CORE LOGGING METHOD
  // ============================================================

  /// Optimized log method with early exit
  void log(Level logLevel, String message, String? tag,
      [Object? error, StackTrace? stackTrace, int depthOffset = 0]) {
    // CRITICAL: Early exit before any expensive operations
    if (!enabled) return;

    // Check if ANY appender would log this level
    if (!isLevelEnabled(logLevel)) {
      return; // EXIT EARLY - Don't generate stack traces!
    }

    // Only NOW do the expensive stack trace generation
    var totalDepthOffset = clientDepthOffset + depthOffset;
    var contextInfo = LoggerStackTrace.from(StackTrace.current,
        depthOffset: totalDepthOffset);
    var record = LogRecord(logLevel, message, tag, contextInfo,
        error: error, stackTrace: stackTrace, loggerName: name);

    // Now append to relevant appenders
    for (var appender in appenders) {
      if (appender.enabled && logLevel >= appender.level) {
        appender.append(record);
      }
    }

    for (var appender in customAppenders) {
      if (appender.enabled && logLevel >= appender.level) {
        appender.append(record);
      }
    }
  }

  // ============================================================
  // CONFIGURATION METHODS
  // ============================================================

  void setEnabled(bool enabled) {
    this.enabled = enabled;
    getSelfLogger()?.logInfo('Logger $name enabled: $enabled');
  }

  void setLevelAll(Level level) {
    for (var appender in appenders) {
      appender.level = level;
    }
    for (var appender in customAppenders) {
      appender.level = level;
    }
    _minLevelDirty = true;
    getSelfLogger()?.logInfo('$name: Set level for all appenders to $level');
  }

  void setLogLevel(Level level) {
    setLevelAll(level);
  }

  void setLogLevelForAppender(String appenderType, Level level) {
    final upperType = appenderType.toUpperCase();
    for (var appender in appenders) {
      if (appender.getType() == upperType) {
        appender.level = level;
        getSelfLogger()
            ?.logInfo('$name: Set level for $upperType appender to $level');
      }
    }
    _minLevelDirty = true;
  }

  void setFormatAll(String format) {
    for (var appender in appenders) {
      appender.format = format;
    }
    getSelfLogger()?.logInfo('$name: Set format for all appenders to $format');
  }

  void setFormat(String appenderType, String format) {
    final upperType = appenderType.toUpperCase();
    for (var appender in appenders) {
      if (appender.getType() == upperType) {
        appender.format = format;
        getSelfLogger()
            ?.logInfo('$name: Set format for appender $upperType to $format');
      }
    }
  }

  void resetFormatToInitialConfig() {
    getSelfLogger()?.logInfo(
        '$name: Resetting format for all appenders to initial config');
    for (var appender in appenders) {
      appender.format = appender.initialFormat;
    }
  }

  void setDateTimeFormatAll(String dateTimeFormat) {
    getSelfLogger()?.logInfo(
        '$name: Setting date format for all appenders to $dateTimeFormat');
    for (var appender in appenders) {
      appender.dateFormat = dateTimeFormat;
    }
  }

  void setDateTimeFormat(String appenderType, String dateTimeFormat) {
    final upperType = appenderType.toUpperCase();
    for (var appender in appenders) {
      if (appender.getType() == upperType) {
        getSelfLogger()?.logInfo(
            '$name: Setting date format for appender $upperType to $dateTimeFormat');
        appender.dateFormat = dateTimeFormat;
      }
    }
  }

  void resetDateTimeFormatToInitialConfig() {
    getSelfLogger()?.logInfo(
        '$name: Resetting date format for all appenders to initial config');
    for (var appender in appenders) {
      appender.dateFormat = appender.initialDateFormat;
    }
  }

  void setClientDepthOffsetAll(int offset) {
    getSelfLogger()?.logInfo(
        '$name: Setting client depth offset for all appenders to $offset');
    for (var appender in appenders) {
      appender.clientDepthOffset = offset;
    }
  }

  void setClientDepthOffset(String appenderType, int offset) {
    final upperType = appenderType.toUpperCase();
    for (var appender in appenders) {
      if (appender.getType() == upperType) {
        getSelfLogger()?.logInfo(
            '$name: Setting client depth offset for appender $upperType to $offset');
        appender.clientDepthOffset = offset;
      }
    }
  }

  // ============================================================
  // APPENDER MANAGEMENT
  // ============================================================

  void addCustomAppender(Appender appender) {
    appenders.add(appender);
    _minLevelDirty = true;
    getSelfLogger()
        ?.logInfo('$name: Added custom ${appender.getType()} appender');
  }

  void registerCustomAppender(Appender appender) {
    customAppenders.add(appender);
    _minLevelDirty = true;
    getSelfLogger()
        ?.logInfo('$name: Registered custom ${appender.getType()} appender');
  }

  void reset() {
    appenders.clear();
    customAppenders.clear();
    _minLevelDirty = true;
    getSelfLogger()?.logInfo('Reset logger $name');
  }

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  Future<void> flush() async {
    try {
      for (var appender in appenders) {
        try {
          // Skip flush for appenders that don't need it
          if (appender.getType() == 'CONSOLE' || appender.getType() == 'FILE') {
            getSelfLogger()?.logTrace(
                '$name: Skipping flush for ${appender.getType()} appender (not needed)');
            continue;
          }

          await appender.flush();
          getSelfLogger()
              ?.logTrace('$name: Flushed ${appender.getType()} appender');
        } catch (e) {
          print('$name:  Error flushing appender ${appender.getType()}: $e');
        }
      }
      for (var appender in customAppenders) {
        try {
          await appender.flush();
          getSelfLogger()?.logTrace(
              '$name: Flushed custom ${appender.getType()} appender');
        } catch (e) {
          print(
              '$name: Error flushing custom appender ${appender.getType()}: $e');
        }
      }
    } catch (e) {
      print('$name: Error in logger flush: $e');
    }
  }

  Future<void> dispose() async {
    // Don't use self-logging during disposal to avoid MDC contamination
    for (var appender in appenders) {
      await appender.dispose();
    }
    for (var appender in customAppenders) {
      await appender.dispose();
    }
    appenders.clear();
    customAppenders.clear();
    _minLevelDirty = true;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get information about this logger's configuration
  Map<String, dynamic> getLoggerInfo() {
    return {
      'name': name,
      'appenders': appenders.map((appender) => appender.getType()).toList(),
      'customAppenders':
          customAppenders.map((appender) => appender.getType()).toList(),
      'clientDepthOffset': clientDepthOffset,
      'enabled': enabled,
      'minLevel': minLevel.name,
    };
  }

  @override
  String toString() {
    return 'Logger(name: $name, appenders: ${appenders.map((a) => a.getType())}, '
        'customAppenders: ${customAppenders.map((a) => a.getType())}, '
        'clientDepthOffset: $clientDepthOffset, enabled: $enabled)';
  }

  // ============================================================
  // SELF-DEBUGGING SUPPORT
  // ============================================================

  /// For the self-debugging system to access internal details
  static Logger? getSelfLogger() {
    return LoggerFactory.selfLogger;
  }

  /// Check if self-debugging is enabled
  static bool isSelfDebugEnabled() {
    return LoggerFactory.selfDebugEnabled;
  }
}
