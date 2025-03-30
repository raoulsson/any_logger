import 'dart:convert';
import 'dart:io';

import '../any_logger_lib.dart';

class Logger {
  List<Appender> appenders = [];
  List<Appender> registeredAppenders = [];
  int clientDepthOffset = 0;
  String? tag;
  String? loggerName;
  static Logger? _instance;

  factory Logger() {
    assert(_instance != null, 'Logger.init(...) not yet called');
    return _instance!;
  }

  Logger._(List<Appender> definedAppenders, List<Appender> activeAppenders,
      {int clientDepthOffset = 0}) {
    registeredAppenders = definedAppenders;
    appenders = activeAppenders;
    this.clientDepthOffset = clientDepthOffset;
  }

  Logger._empty();

  static Logger get instance {
    assert(_instance != null, 'Logger.init(...) not yet called');
    return _instance!;
  }

  static Future<bool> initFromFile(String fileName) async {
    var fileContents = File(fileName).readAsStringSync();
    var jsonData = json.decode(fileContents);
    return await init(jsonData);
  }

  static Future<bool> init(Map<String, dynamic>? config,
      {bool test = false,
      DateTime? date,
      int clientProxyCallDepthOffset = 0}) async {
    if (config == null || config.isEmpty) {
      _instance = Logger._empty();
      return true;
    }

    var activeAppenders = <Appender>[];
    for (Map<String, dynamic> app in config['appenders']) {
      if (!app.containsKey('type')) {
        throw ArgumentError('Missing type for appender');
      }

      final appenderTypeString = app['type'].toString().toUpperCase();
      try {
        final appenderType = AppenderType.values.firstWhere(
              (type) => type.name == appenderTypeString,
          orElse: () => throw FormatException('Unknown appender type: ${app['type']}'),
        );

        Appender appender =
            await appenderType.createFromConfig(app, test: test, date: date);
        activeAppenders.add(appender);
      } on FormatException catch (e) {
        throw ArgumentError(e.message);
      }
    }

    var definedAppenders =
        AppenderType.values.map((type) => type.createAppender()).toList();

    _instance = Logger._(definedAppenders, activeAppenders,
        clientDepthOffset: clientProxyCallDepthOffset);
    return true;
  }

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
        object: object,
        loggerName: loggerName);
    for (var app in appenders) {
      if (logLevel >= app.level) {
        app.append(record);
      }
    }
  }

  static void trace(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.TRACE, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  static void debug(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.DEBUG, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  static void info(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.INFO, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  static void warn(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.WARN, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  static void error(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.ERROR, message, tag, exception?.toString(),
        stackTrace, object, kStackDepthOffset);
  }

  static void fatal(String message,
      {String? tag,
      Object? exception,
      StackTrace? stackTrace,
      Object? object}) {
    tag ??= '';
    Logger.instance.log(Level.FATAL, message, tag, exception?.toString(),
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
}
