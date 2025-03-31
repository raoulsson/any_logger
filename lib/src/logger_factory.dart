import 'dart:convert';
import 'dart:io';

import '../any_logger_lib.dart';

class LoggerFactory {
  static final Map<String, Logger> _loggers = {};
  static Logger? _rootLogger;

  /// Initialize the logging system with a configuration
  static Future<bool> init(Map<String, dynamic>? config, {
    bool test = false,
    DateTime? date,
    int clientProxyCallDepthOffset = 0
  }) async {
    if (config == null || config.isEmpty) {
      _rootLogger = Logger.empty();
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

        Appender appender = await appenderType.createFromConfig(app, test: test, date: date);
        activeAppenders.add(appender);
      } on FormatException catch (e) {
        throw ArgumentError(e.message);
      }
    }

    var definedAppenders = AppenderType.values.map((type) => type.createAppender()).toList();

    _rootLogger = Logger.defaultLogger(definedAppenders, activeAppenders,
        clientDepthOffset: clientProxyCallDepthOffset);

    // Add the default logger to the map with the ROOT name
    _loggers['ROOT'] = _rootLogger!;

    return true;
  }

  /// Initialize the logging system from a configuration file
  static Future<bool> initFromFile(String fileName) async {
    var fileContents = File(fileName).readAsStringSync();
    var jsonData = json.decode(fileContents);
    return await init(jsonData);
  }

  /// Get a named logger instance
  static Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      if (_rootLogger == null) {
        throw StateError('Logger has not been initialized yet. Call LoggerFactory.init() first.');
      }
      // Create a new logger based on the default one but with a different name
      _loggers[name] = Logger.fromExisting(_rootLogger!, name: name);
    }
    return _loggers[name]!;
  }

  /// Get the default logger instance
  static Logger getRootLogger() {
    if (_rootLogger == null) {
      throw StateError('Logger has not been initialized yet. Call LoggerFactory.init() first.');
    }
    return _rootLogger!;
  }
}
