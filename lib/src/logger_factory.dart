import 'dart:convert';
import 'dart:io';

import '../any_logger_lib.dart';

class LoggerFactory {
  static const String ROOT_LOGGER = 'ROOT_LOGGER';
  static final Map<String, Logger> _loggers = {};
  static Logger? _rootLogger;
  static Logger? _selfLogger;
  static bool _selfDebugEnabled = false;
  static Level _selfLogLevel = Level.INFO;

  /// Get the library's self-logging logger
  static Logger? get selfLogger => _selfLogger;

  /// Whether self-debugging is enabled
  static bool get selfDebugEnabled => _selfDebugEnabled;

  /// Initialize the logging system with a configuration
  static Future<bool> init(Map<String, dynamic>? config,
      {bool test = false,
      DateTime? date,
      int clientProxyCallDepthOffset = 0,
      bool selfDebug = false, Level selfLogLevel = Level.INFO}) async {
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    if (config == null || config.isEmpty) {
      _rootLogger = Logger.empty();

      if (selfDebug) {
        _setupSelfLogger();
      }

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
          orElse: () =>
              throw FormatException('Unknown appender type: ${app['type']}'),
        );

        Appender appender =
            await appenderType.createFromConfig(app, test: test, date: date);
        activeAppenders.add(appender);

        if (selfDebug) {
          _selfLog('Initialized appender: ${appenderType.name}');
        }
      } on FormatException catch (e) {
        if (selfDebug) {
          _selfLog('Error creating appender: ${e.message}',
              level: Level.ERROR);
        }
        throw ArgumentError(e.message);
      }
    }

    var definedAppenders =
        AppenderType.values.map((type) => type.createAppender()).toList();

    _rootLogger = Logger.defaultLogger(definedAppenders, activeAppenders,
        clientDepthOffset: clientProxyCallDepthOffset);

    // Add the root logger to the map with the ROOT_LOGGER name
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _selfLog(
          'Logging system initialized with ${activeAppenders.length} active appenders');
    }

    return true;
  }

  /// Set up the self-logging logger
  static void _setupSelfLogger() {
    if (_rootLogger == null) return;

    const selfLoggerName = 'ANY_DEBUG_LOGGER';
    _selfLogger = Logger.fromExisting(_rootLogger!, name: selfLoggerName);
    _selfLogger?.setLevelAll(_selfLogLevel);
    _loggers[selfLoggerName] = _selfLogger!;
    _selfLog('Self-debugging enabled');
  }

  /// Log a message using the self logger
  static void _selfLog(String message, {Level level = Level.DEBUG}) {
    if (!_selfDebugEnabled || _selfLogger == null) return;

    switch (level) {
      case Level.TRACE:
        _selfLogger!.logTrace(message, tag: 'AnyLoggerLib');
        break;
      case Level.DEBUG:
        _selfLogger!.logDebug(message, tag: 'AnyLoggerLib');
        break;
      case Level.INFO:
        _selfLogger!.logInfo(message, tag: 'AnyLoggerLib');
        break;
      case Level.WARN:
        _selfLogger!.logWarn(message, tag: 'AnyLoggerLib');
        break;
      case Level.ERROR:
        _selfLogger!.logError(message, tag: 'AnyLoggerLib');
        break;
      case Level.FATAL:
        _selfLogger!.logFatal(message, tag: 'AnyLoggerLib');
        break;
      default:
        _selfLogger!.logDebug(message, tag: 'AnyLoggerLib');
    }
  }

  /// Initialize the logging system from a configuration file
  static Future<bool> initFromFile(String fileName,
      {bool selfDebug = false}) async {
    if (selfDebug) {
      // Can't use _selfDebug yet since the logger isn't initialized
      print('[SELF_DEBUG] Loading config from file: $fileName');
    }

    var fileContents = File(fileName).readAsStringSync();
    var jsonData = json.decode(fileContents);
    return await init(jsonData, selfDebug: selfDebug);
  }

  /// Get a named logger instance
  static Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      if (_rootLogger == null) {
        throw StateError(
            'Logger has not been initialized yet. Call await LoggerFactory.init() first.');
      }
      // Create a new logger based on the ROOT_LOGGER one but with a different name
      _loggers[name] = Logger.fromExisting(_rootLogger!, name: name);

      if (_selfDebugEnabled) {
        _selfLog('Created new logger: $name');
      }
    }
    return _loggers[name]!;
  }

  /// Get the ROOT_LOGGER logger instance
  static Logger getRootLogger() {
    if (_rootLogger == null) {
      throw StateError(
          'Logger has not been initialized yet. Call await LoggerFactory.init() first.');
    }
    return _rootLogger!;
  }

  /// Get a list of all logger names
  static List<String> getAllLoggerNames() {
    return _loggers.keys.toList();
  }

  /// Reset all loggers (for testing)
  static void resetAll() {
    _selfLog('Resetting all loggers');
    _loggers.clear();
    _rootLogger = null;
    _selfLogger = null;
    _selfDebugEnabled = false;
    _selfLogLevel = Level.INFO;
  }
}
