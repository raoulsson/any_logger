import 'dart:convert';
import 'dart:io';

import '../any_logger_lib.dart';

typedef HttpCompleteCallback = void Function();

class LoggerFactory {
  static const ANYLOGGER_SELF_LOGGER_NAME = 'ANYLOGGER_SELF_LOGGER';
  /// Callback for when HTTP operations are completed
  static HttpCompleteCallback? onHttpComplete;

  static const String ROOT_LOGGER = 'ROOT_LOGGER';
  static final Map<String, Logger> _loggers = {};
  static Logger? _rootLogger;
  static Logger? _selfLogger;
  static bool _selfDebugEnabled = false;
  static Level _selfLogLevel = Level.DEBUG;

  static String? _deviceId = null;
  static String? _sessionId = null;
  static String? _appVersion = null;
  static String? _deviceIdentifier = null;

  /// Get the library's self-logging logger
  static Logger? get selfLogger => _selfLogger;

  /// Whether self-debugging is enabled
  static bool get selfDebugEnabled => _selfDebugEnabled;

  static String? getDeviceId() {
    return _deviceId;
  }

  static String? getSessionId() {
    return _sessionId;
  }

  static void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  static void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  static String? getAppVersion() {
    return _appVersion;
  }

  static void setAppVersion(String appVersion) {
    _appVersion = appVersion;
  }

  static void setDeviceIdentifier(String? deviceId) {
    _deviceIdentifier = deviceId;
  }

  static String? getDeviceIdentifier() {
    return _deviceIdentifier;
  }

  /// Initialize the logging system with a configuration
  static Future<bool> init(
    Map<String, dynamic>? config, {
    bool test = false,
    DateTime? date,
    int clientProxyCallDepthOffset = 0,
    bool selfDebug = false,
    Level selfLogLevel = Level.INFO,
    String? deviceId = null,
    String? sessionId = null,
    String? appVersion = null,
  }) async {
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;
    _deviceId = deviceId;
    _sessionId = sessionId;
    _appVersion = appVersion;

    if (config == null || config.isEmpty) {
      _rootLogger = Logger.empty();

      if (selfDebug) {
        _setupSelfLogger();
      }

      return true;
    }

    var appendersFromConfig = <Appender>[];
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
        appendersFromConfig.add(appender);

        if (selfDebug) {
          _selfLog('Initialized appender: ${appenderType.name}. Appender: ${appender.toString()}');
        }
      } on FormatException catch (e) {
        if (selfDebug) {
          _selfLog('Error creating appender: ${e.message}', level: Level.ERROR);
        }
        throw ArgumentError(e.message);
      }
    }

    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);

    // Add the root logger to the map with the ROOT_LOGGER name
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _selfLog(
          'Logging system initialized with ${appendersFromConfig.length} active appenders');
      for(var appender in appendersFromConfig) {
        _selfLog('Appender: ${appender.getType()}, Level: ${appender.level}, Format: ${appender.format}, DateFormat: ${appender.dateFormat}');
      }
    }

    return true;
  }

  /// Set up the self-logging logger
  static void _setupSelfLogger() {
    if (_rootLogger == null) return;

    _selfLogger = Logger.fromExisting(_rootLogger!,
        name: ANYLOGGER_SELF_LOGGER_NAME, consoleOnly: true);
    _selfLogger?.setLevelAll(_selfLogLevel);
    _loggers[ANYLOGGER_SELF_LOGGER_NAME] = _selfLogger!;
    _selfLog('Self-debugging enabled');
  }

  static Future<void> dispose() async {
    _selfLog('Disposing logger factory');
    for (var logger in _loggers.values) {
      logger.dispose();
    }
    _loggers.clear();
    _rootLogger = null;
    _selfLogger = null;
    _selfDebugEnabled = false;
    _selfLogLevel = Level.INFO;
  }

  /// Log a message using the self logger
  static void _selfLog(String message, {Level? level = null}) {
    if (!_selfDebugEnabled || _selfLogger == null) return;

    if (level == null) {
      level = _selfLogLevel;
    }

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

  static enableAppender(AppenderType appenderType) {
    for(Logger logger in _loggers.values) {
      print('Enabling appender $appenderType for logger ${logger.name}. Found Appenders: ${logger.appenders.map((a) => a.getType()).join(', ')}');
      if (logger.appenders.contains(appenderType)) {
        logger.appenders.firstWhere((appender) => appender.getType() == appenderType).setEnabled(true);
        selfLogger?.logInfo(
            'Appender $appenderType enabled for logger ${logger.name}');
      } else {
        selfLogger?.logWarn(
            'Appender $appenderType not found, cannot enable it');
      }
    }

  }

  static disableAppender(AppenderType appenderType) {
    for(Logger logger in _loggers.values) {
      print('Disabling appender $appenderType for logger ${logger.name}. Found Appenders: ${logger.appenders.map((a) => a.getType()).join(', ')}');
      if (logger.appenders.contains(appenderType)) {
        logger.appenders.firstWhere((appender) => appender.getType() == appenderType).setEnabled(false);
        selfLogger?.logInfo(
            'Appender $appenderType disabled for logger ${logger.name}');
      } else {
        selfLogger?.logWarn(
            'Appender $appenderType not found, cannot disable it');
      }
    }
  }

  /// Get a list of all logger names
  static List<String> getAllLoggerNames() {
    return _loggers.keys.toList();
  }

  static void logLogger2AppendersInfo() {
    for (var logger in _loggers.values) {
      for (var appender in logger.appenders) {
        print(
            'Logger: ${logger.name}, Appender: ${appender.getType()}, Level: ${appender.level}, Format: ${appender.format}, DateFormat: ${appender.dateFormat}');
      }
    }
  }

  static flushAll() {
    _selfLog('Flushing all loggers');
    for (var logger in _loggers.values) {
      logger.flush();
    }
  }
}
