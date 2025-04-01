import '../any_logger_lib.dart';

class Logger {
  List<Appender> appenders = [];
  List<Appender> customAppenders = [];
  int clientDepthOffset = 0;
  String? tag;
  String name;

  Logger.defaultLogger(
      List<Appender> appendersFromConfig, {
      int clientDepthOffset = 0,
      String? name}
      ) : this.name = name ?? LoggerFactory.ROOT_LOGGER {
    getSelfLogger()?.logInternalState('Creating default logger with name: $name');
    appenders = appendersFromConfig;
    this.clientDepthOffset = clientDepthOffset;
  }

  /// Create a new logger from an existing one, but with a different name
  Logger.fromExisting(Logger other, {required String name, bool consoleOnly = false})
      : this.name = name,
        clientDepthOffset = other.clientDepthOffset {
    getSelfLogger()?.logInternalState(
        'Creating new logger named $name from existing logger: ${other.name}');
    // Create deep copies of appenders so each logger has independent instances
    appenders = other.appenders.map((appender) {
      // Create a new appender of the same type
      Appender newAppender = AppenderType.values
          .firstWhere((type) => type.name == appender.getType())
          .createAppender();

      // Copy configuration from the original appender
      newAppender.level = appender.level;
      newAppender.format = appender.format;
      newAppender.initialFormat = appender.initialFormat;
      newAppender.dateFormat = appender.dateFormat;
      newAppender.initialDateFormat = appender.initialDateFormat;
      newAppender.clientDepthOffset = appender.clientDepthOffset;

      return newAppender;
    }).toList();

    if(consoleOnly) {
      appenders.removeWhere((appender) => appender.getType() != AppenderType.CONSOLE.name);
    }

    // Same for registered appenders
    customAppenders = other.customAppenders.map((appender) {
      Appender newAppender = AppenderType.values
          .firstWhere((type) => type.name == appender.getType())
          .createAppender();

      newAppender.level = appender.level;
      newAppender.format = appender.format;
      newAppender.dateFormat = appender.dateFormat;
      newAppender.clientDepthOffset = appender.clientDepthOffset;

      return newAppender;
    }).toList();

    if(consoleOnly) {
      customAppenders.removeWhere((appender) => appender.getType() != AppenderType.CONSOLE.name);
    }

    tag = other.tag;
  }

  Logger.empty() : name = LoggerFactory.ROOT_LOGGER;

  Future<void> dispose() async {
    getSelfLogger()?.logInternalState('Disposing logger: $name');
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
    getSelfLogger()?.logInternalState('Flushing logger: $name');
    for (var appender in appenders) {
      await appender.flush();
    }
    for (var appender in customAppenders) {
      await appender.flush();
    }
  }

  void setFormatAll(String format) {
    getSelfLogger()
        ?.logInternalState('Setting format for all appenders to $format');
    for (var appender in appenders) {
      appender.format = format;
    }
  }

  void setFormat(AppenderType appenderType, String format) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInternalState(
            'Setting format for appender ${appender.getType()} to $format');
        appender.format = format;
      }
    }
  }

  void resetFormatToInitialConfig() {
    getSelfLogger()?.logInternalState(
        'Resetting format for all appenders to initial config');
    for (var appender in appenders) {
      appender.format = appender.initialFormat;
    }
  }

  void setLevelAll(Level level) {
    getSelfLogger()
        ?.logInternalState('Setting level for all appenders to $level');
    for (var appender in appenders) {
      appender.level = level;
    }
  }

  void setLevel(AppenderType appenderType, Level level) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInternalState(
            'Setting level for appender ${appender.getType()} to $level');
        appender.level = level;
      }
    }
  }

  void setDateTimeFormatAll(String dateTimeFormat) {
    getSelfLogger()?.logInternalState(
        'Setting date format for all appenders to $dateTimeFormat');
    for (var appender in appenders) {
      appender.dateFormat = dateTimeFormat;
    }
  }

  void setDateTimeFormat(AppenderType appenderType, String dateTimeFormat) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInternalState(
            'Setting date format for appender ${appender.getType()} to $dateTimeFormat');
        appender.dateFormat = dateTimeFormat;
      }
    }
  }

  void resetDateTimeFormatToInitialConfig() {
    getSelfLogger()?.logInternalState(
        'Resetting date format for all appenders to initial config');
    for (var appender in appenders) {
      appender.dateFormat = appender.initialDateFormat;
    }
  }

  void setClientDepthOffsetAll(int offset) {
    getSelfLogger()?.logInternalState(
        'Setting client depth offset for all appenders to $offset');
    for (var appender in appenders) {
      appender.clientDepthOffset = offset;
    }
  }

  void setClientDepthOffset(AppenderType appenderType, int offset) {
    for (var appender in appenders) {
      if (appender.getType() == appenderType.name) {
        getSelfLogger()?.logInternalState(
            'Setting client depth offset for appender ${appender.getType()} to $offset');
        appender.clientDepthOffset = offset;
      }
    }
  }

  void log(Level logLevel, String message, String? tag,
      [Object? error, StackTrace? stackTrace, int depthOffset = 0]) {
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

  /// Log a message about the logger's state
  void logInternalState(String message) {
    logInfo('Logger State: $message', tag: 'LoggerState');
  }

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
    getSelfLogger()
        ?.logInternalState('Adding custom appender: ${appender.getType()}');
    appenders.add(appender);
  }

  void reset() {
    getSelfLogger()?.logInternalState('Resetting logger: $name');
    appenders.clear();
  }

  void registerCustomAppender(Appender appender) {
    getSelfLogger()
        ?.logInternalState('Registering appender: ${appender.getType()}');
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
