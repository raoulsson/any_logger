
import '../any_logger_lib.dart';
import 'logger_factory.dart';

class Logger {
  List<Appender> appenders = [];
  List<Appender> registeredAppenders = [];
  int clientDepthOffset = 0;
  String? tag;
  String name;

  Logger.defaultLogger(List<Appender> definedAppenders, List<Appender> activeAppenders,
      {int clientDepthOffset = 0, String? name})
      : this.name = name ?? 'ROOT' {
    registeredAppenders = definedAppenders;
    appenders = activeAppenders;
    this.clientDepthOffset = clientDepthOffset;
  }

  /// Create a new logger from an existing one, but with a different name
  Logger.fromExisting(Logger other, {required String name})
      : this.name = name,
        clientDepthOffset = other.clientDepthOffset {
    appenders = List.from(other.appenders);
    registeredAppenders = List.from(other.registeredAppenders);
    tag = other.tag;
  }

  Logger.empty() : name = 'ROOT';

  void log(Level logLevel, String message, String? tag,
      [Object? error,
        StackTrace? stackTrace,
        Object? object,
        int depthOffset = 0]) {
    var totalDepthOffset = clientDepthOffset + depthOffset;
    var contextInfo = LoggerStackTrace.from(StackTrace.current,
        depthOffset: totalDepthOffset);
    var record = LogRecord(logLevel, message, tag, contextInfo,
        error: error,
        stackTrace: stackTrace,
        loggerName: name);
    for (var app in appenders) {
      if (logLevel >= app.level) {
        app.append(record);
      }
    }
  }

  void logTrace(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.TRACE, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void logDebug(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.DEBUG, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void logInfo(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.INFO, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void logWarn(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.WARN, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void logError(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.ERROR, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void logFatal(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    tag ??= '';
    log(Level.FATAL, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  void addCustomAppender(Appender appender) {
    appenders.add(appender);
  }

  void reset() {
    appenders.clear();
  }

  void registerAppender(Appender appender) {
    registeredAppenders.add(appender);
  }

  void registerAllAppender(List<Appender> appender) {
    registeredAppenders.addAll(appender);
  }

  /// For backward compatibility with the static methods
  static void trace(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logTrace(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  static void debug(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logDebug(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  static void info(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logInfo(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  static void warn(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logWarn(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  static void error(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logError(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  static void fatal(String message,
      {String? tag,
        Object? exception,
        StackTrace? stackTrace,
        Object? object}) {
    LoggerFactory.getRootLogger().logFatal(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }
}