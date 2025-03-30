import 'logger.dart';

/// Meant to be mixed into client classes that need login.
///
/// class Client with AnyLogger {
///     ...
///     logDebug(...);
///     ...
///
/// Alternatively, use Logger.debug(...) etc directly.
/// In either case, call Logger.init(config) once in main!
mixin AnyLogger {
  void logTrace(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.trace(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logDebug(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.debug(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logInfo(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.info(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logWarn(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.warn(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logError(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.error(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }

  void logFatal(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    Logger.fatal(message,
        tag: tag, exception: exception, stackTrace: stackTrace, object: object);
  }
}
