import '../any_logger_lib.dart';

class Logger {
  List<Appender> appenders = [];
  List<Appender> customAppenders = [];
  int clientDepthOffset = 0;
  String? tag;
  String name;
  bool enabled = true;

  Logger.defaultLogger(List<Appender> appendersFromConfig,
      {int clientDepthOffset = 0, String? name})
      : this.name = name ?? LoggerFactory.ROOT_LOGGER {
    getSelfLogger()?.logInfo('Creating default logger with name: $name');
    appenders = appendersFromConfig;
    this.clientDepthOffset = clientDepthOffset;
  }

  Logger.fromExisting(Logger other,
      {required String name, bool consoleOnly = false})
      : this.name = name,
        clientDepthOffset = other.clientDepthOffset {
    getSelfLogger()?.logInfo(
        'Creating new logger named $name from existing logger: ${other.name}');

    // Create deep copies of appenders using the createDeepCopy method
    appenders =
        other.appenders.map((appender) => appender.createDeepCopy()).toList();

    if (consoleOnly) {
      appenders.removeWhere(
          (appender) => appender.getType() != AppenderType.CONSOLE.name);
    }

    // Same for custom appenders
    customAppenders = other.customAppenders
        .map((appender) => appender.createDeepCopy())
        .toList();

    if (consoleOnly) {
      customAppenders.removeWhere(
          (appender) => appender.getType() != AppenderType.CONSOLE.name);
    }

    tag = other.tag;
  }

  Logger.empty() : name = LoggerFactory.ROOT_LOGGER;

  Future<void> dispose() async {
    getSelfLogger()?.logInfo('Disposing logger: $name');
    for (var appender in appenders) {
      await appender.dispose();
    }
    for (var appender in customAppenders) {
      await appender.dispose();
    }
    appenders.clear();
    customAppenders.clear();
  }

  Future<void> flush() async {
    try {
      getSelfLogger()?.logInfo('Flushing logger: $name');
      for (var appender in appenders) {
        try {
          getSelfLogger()?.logDebug('Flushing appender: ${appender.getType()}');
          await appender.flush();
        } catch (e, stackTrace) {
          getSelfLogger()
              ?.logError('Error flushing appender ${appender.getType()}: $e');
          // Optionally log the stack trace if needed
          // getSelfLogger()?.logDebug('Stack trace: $stackTrace');
        }
      }
      for (var appender in customAppenders) {
        try {
          getSelfLogger()
              ?.logDebug('Flushing custom appender: ${appender.getType()}');
          await appender.flush();
        } catch (e, stackTrace) {
          getSelfLogger()?.logError(
              'Error flushing custom appender ${appender.getType()}: $e');
          // Optionally log the stack trace if needed
          // getSelfLogger()?.logDebug('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      // This catches any errors in the overall flush operation
      print('Error in logger flush: $e');
      // print('Stack trace: $stackTrace');
    }
  }

  void setFormatAll(String format) {
    getSelfLogger()?.logInfo('Setting format for all appenders to $format');
    for (var appender in appenders) {
      appender.format = format;
    }
  }

  void setFormat(AppenderType appenderType, String format) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInfo(
            'Setting format for appender ${appender.getType()} to $format');
        appender.format = format;
      }
    }
  }

  void resetFormatToInitialConfig() {
    getSelfLogger()
        ?.logInfo('Resetting format for all appenders to initial config');
    for (var appender in appenders) {
      appender.format = appender.initialFormat;
    }
  }

  void setLevelAll(Level level) {
    getSelfLogger()?.logInfo('Setting level for all appenders to $level');
    for (var appender in appenders) {
      appender.level = level;
    }
  }

  void setLogLevelForAppender(AppenderType appenderType, Level level) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInfo(
            'Setting level for appender ${appender.getType()} to $level');
        appender.level = level;
      }
    }
  }

  void setLogLevel(Level level) {
    for (var appender in appenders) {
      getSelfLogger()?.logInfo(
          'Setting level for appender ${appender.getType()} to $level');
      appender.level = level;
    }
  }

  void setDateTimeFormatAll(String dateTimeFormat) {
    getSelfLogger()
        ?.logInfo('Setting date format for all appenders to $dateTimeFormat');
    for (var appender in appenders) {
      appender.dateFormat = dateTimeFormat;
    }
  }

  void setDateTimeFormat(AppenderType appenderType, String dateTimeFormat) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInfo(
            'Setting date format for appender ${appender.getType()} to $dateTimeFormat');
        appender.dateFormat = dateTimeFormat;
      }
    }
  }

  void resetDateTimeFormatToInitialConfig() {
    getSelfLogger()
        ?.logInfo('Resetting date format for all appenders to initial config');
    for (var appender in appenders) {
      appender.dateFormat = appender.initialDateFormat;
    }
  }

  void setClientDepthOffsetAll(int offset) {
    getSelfLogger()
        ?.logInfo('Setting client depth offset for all appenders to $offset');
    for (var appender in appenders) {
      appender.clientDepthOffset = offset;
    }
  }

  void setClientDepthOffset(AppenderType appenderType, int offset) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInfo(
            'Setting client depth offset for appender ${appender.getType()} to $offset');
        appender.clientDepthOffset = offset;
      }
    }
  }

  bool isEnabled(Level logLevel) {
    return enabled;
  }

  void setEnabled(bool enabled) {
    this.enabled = enabled;
    getSelfLogger()?.logInfo('Setting logger $name enabled state to $enabled');
  }

  void log(Level logLevel, String message, String? tag,
      [Object? error, StackTrace? stackTrace, int depthOffset = 0]) {
    if(!enabled) {
      return;
    }
    var totalDepthOffset = clientDepthOffset + depthOffset;
    var contextInfo = LoggerStackTrace.from(StackTrace.current,
        depthOffset: totalDepthOffset);
    var record = LogRecord(logLevel, message, tag, contextInfo,
        error: error, stackTrace: stackTrace, loggerName: name);
    for (var app in appenders) {
      if (logLevel >= app.level) {
        app.append(record);
      }
    }
  }

  // /// Log a message about the logger's state
  // void logDebugInternalState(String message) {
  //   logDebug('$message', tag: 'LoggerState');
  // }
  //
  // /// Log a message about the logger's state
  // void logInfoInternalState(String message) {
  //   logInfo('$message', tag: 'LoggerState');
  // }

  /// Get information about this logger's configuration
  Map<String, dynamic> getLoggerInfo() {
    return {
      'name': name,
      'appenders': appenders.map((appender) => appender.getType()).toList(),
      // 'registeredAppenders':
      //     registeredAppenders.map((appender) => appender.getType()).toList(),
      'clientDepthOffset': clientDepthOffset,
    };
  }

  void addCustomAppender(Appender appender) {
    getSelfLogger()?.logInfo('Adding custom appender: ${appender.getType()}');
    appenders.add(appender);
  }

  void reset() {
    getSelfLogger()?.logInfo('Resetting logger: $name');
    appenders.clear();
  }

  void registerCustomAppender(Appender appender) {
    getSelfLogger()?.logInfo('Registering appender: ${appender.getType()}');
    customAppenders.add(appender);
  }

  @override
  String toString() {
    return 'Logger(name: $name, appenders: ${appenders.map((a) => a.getType())}, customAppenders: ${customAppenders.map((a) => a.getType())}, clientDepthOffset: $clientDepthOffset)';
  }

  void logTrace(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.TRACE, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logDebug(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.DEBUG, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logInfo(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.INFO, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logWarn(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.WARN, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logError(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.ERROR, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  void logFatal(String message,
      {String? tag, Object? exception, StackTrace? stackTrace}) {
    tag ??= '';
    log(Level.FATAL, message, tag, exception?.toString(), stackTrace,
        kStackDepthOffset);
  }

  /// For backward compatibility with the static methods
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

  /// For the self-debugging system to access internal details
  static Logger? getSelfLogger() {
    return LoggerFactory.selfLogger;
  }

  /// Check if self-debugging is enabled
  static bool isSelfDebugEnabled() {
    return LoggerFactory.selfDebugEnabled;
  }
}
