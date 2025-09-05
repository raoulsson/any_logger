import 'dart:convert';
import 'dart:io';

import '../any_logger.dart';

typedef HttpCompleteCallback = void Function();

/// Factory for creating and managing loggers
class LoggerFactory {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String ROOT_LOGGER = 'ROOT_LOGGER';
  static const String ANYLOGGER_SELF_LOGGER_NAME = 'ANYLOGGER_SELF_LOGGER';

  // ============================================================
  // STATIC FIELDS
  // ============================================================

  // Logger instances
  static final Map<String, Logger> _loggers = {};
  static Logger? _rootLogger;
  static Logger? _selfLogger;

  // Configuration state
  static bool _initialized = false;

  // Self-debugging
  static bool _selfDebugEnabled = false;
  static Level _selfLogLevel = Level.DEBUG;

  // ID Provider
  static IdProvider? _idProvider;
  static bool _deviceIdNeeded = false;
  static bool _sessionIdNeeded = false;
  static bool _fileAppenderNeeded = false;

  // Flutter apps MUST set this or logging will fail
  static Future<Directory> Function()? _getAppDocumentsDirectoryFnc;

  // Metadata
  static String? _appVersion;

  // MDC (Mapped Diagnostic Context) storage
  static final Map<String, String> _mdcContext = {};

  // Callbacks
  static HttpCompleteCallback? onHttpComplete;

  // ============================================================
  // ID PROVIDER CONFIGURATION
  // ============================================================
  static void setGetAppDocumentsDirectoryFnc(
      Future<Directory> Function() getAppDocumentsDirectoryFnc) {
    _getAppDocumentsDirectoryFnc = getAppDocumentsDirectoryFnc;
    FileIdProvider.getAppDocumentsDirectoryFnc = getAppDocumentsDirectoryFnc;
    FileAppender.getAppDocumentsDirectoryFnc = getAppDocumentsDirectoryFnc;
  }

  /// Set a custom ID provider (must be called before initialization)
  static void setIdProvider(IdProvider provider) {
    if (_initialized) {
      throw StateError('Cannot set ID provider after initialization. '
          'Call setIdProvider() before any init methods.');
    }
    _idProvider = provider;
  }

  static IdProvider get idProvider {
    _idProvider ??= _createDefaultProvider();
    return _idProvider!;
  }

  /// Create the appropriate default provider based on platform and needs
  static IdProvider _createDefaultProvider() {
    return IdProviderResolver.resolveProvider(
      deviceIdNeeded: _deviceIdNeeded,
      sessionIdNeeded: _sessionIdNeeded,
      fileAppenderNeeded: _fileAppenderNeeded,
      getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
    );
  }

  // ============================================================
  // GETTERS FOR INTERNAL STATE
  // ============================================================

  static Logger? get selfLogger => _selfLogger;

  static bool get selfDebugEnabled => _selfDebugEnabled;

  static String? get deviceId => idProvider.deviceId;

  static String? get sessionId => idProvider.sessionId;

  static String? get appVersion => _appVersion;

  // ============================================================
  // ZERO CONFIG - Just start logging with defaults
  // ============================================================

  /// Get the root logger (auto-initializes with defaults if needed)
  static Logger getRootLogger() {
    if (!_initialized) {
      initSimpleConsole();
    }
    if (_rootLogger == null) {
      throw StateError('Failed to initialize root logger');
    }
    return _rootLogger!;
  }

  /// Get a named logger (auto-initializes if needed)
  static Logger getLogger(String name) {
    if (!_initialized) {
      initSimpleConsole();
    }

    return _loggers.putIfAbsent(name, () {
      if (_rootLogger == null) {
        throw StateError('Root logger not initialized');
      }

      final newLogger = Logger.fromExisting(_rootLogger!, name: name);

      if (_selfDebugEnabled) {
        selfLog('Created logger: $name', logLevel: Level.INFO);
      }

      return newLogger;
    });
  }

  /// Register a custom logger for retrieval via getLogger()
  ///
  /// This method is used internally by Logger.defaultLogger to auto-register
  /// named loggers, but can also be called directly if needed.
  static void registerCustomLogger(Logger logger) {
    if (!_initialized) {
      initSimpleConsole();
    }

    _loggers[logger.name] = logger;

    if (_selfDebugEnabled) {
      selfLog('Registered custom logger: ${logger.name}', logLevel: Level.INFO);
    }
  }

  /// Create a custom logger with specific appenders that can be retrieved later by name
  ///
  /// This is the recommended way to create loggers with custom appenders that need to
  /// be accessible via LoggerFactory.getLogger(name).
  ///
  /// Example:
  /// ```dart
  /// final appender = await FileAppender.fromConfig({'filePattern': 'my-log'});
  /// final logger = LoggerFactory.createCustomLogger('MyLogger', [appender]);
  /// // Later: LoggerFactory.getLogger('MyLogger') returns the same logger
  /// ```
  static Logger createCustomLogger(
    String name,
    List<Appender> appenders, {
    int clientDepthOffset = 0,
  }) {
    if (!_initialized) {
      initSimpleConsole();
    }

    final logger = Logger.defaultLogger(
      appenders,
      name: name,
      clientDepthOffset: clientDepthOffset,
    );

    _loggers[name] = logger;

    if (_selfDebugEnabled) {
      selfLog('Created and registered custom logger: $name',
          logLevel: Level.INFO);
    }

    return logger;
  }

  // ============================================================
  // SIMPLE ONE-LINER INITIALIZATIONS
  // ============================================================

  /// Simplest initialization - console only with defaults
  static void initSimpleConsole({Level level = Level.INFO}) {
    final config = {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': '%d [%l] %m',
          'level': level.name,
          'dateFormat': 'HH:mm:ss.SSS',
        }
      ]
    };

    initSync(config);
    selfLog('Initialized simple console logger with level ${level.name}',
        logLevel: Level.INFO);
  }

  /// Initialize with professional console format (includes file location, method info)
  static void initProConsole({
    Level level = Level.DEBUG,
    String dateFormat = 'HH:mm:ss.SSS',
    bool includeIds = false,
  }) {
    _initializeIdentification();

    String format = includeIds
        ? '[%d][%did][%sid][%i][%l][%c] %m [%f]'
        : '[%d][%i][%l][%c] %m [%f]';

    final config = {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': format,
          'level': level.name,
          'dateFormat': dateFormat,
        }
      ]
    };

    initSync(config);
    selfLog('Initialized professional console logger with level ${level.name}',
        logLevel: Level.INFO);
  }

  /// Initialize with custom console format
  static void initConsole({
    String format = '%d [%l] %m',
    Level level = Level.INFO,
    String dateFormat = 'HH:mm:ss.SSS',
  }) {
    _initializeIdentification();

    final config = {
      'appenders': [
        {
          'type': 'CONSOLE',
          'format': format,
          'level': level.name,
          'dateFormat': dateFormat,
        }
      ]
    };

    initSync(config);
    selfLog('Initialized custom console logger with level ${level.name}',
        logLevel: Level.INFO);
  }

  /// Initialize with file logging (and optional console)
  static Future<void> initFile({
    required String filePattern,
    Level fileLevel = Level.DEBUG,
    Level? consoleLevel,
    String path = '',
    String format = '%d [%l][%t] %c - %m [%f]',
    String? appVersion,
  }) async {
    await _initializeIdentificationAsync();

    final appenders = <Map<String, dynamic>>[];

    appenders.add({
      'type': 'FILE',
      'format': format,
      'level': fileLevel.name,
      'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      'filePattern': filePattern,
      'fileExtension': 'log',
      'rotationCycle': 'DAY',
      'path': path,
    });

    if (consoleLevel != null) {
      appenders.add({
        'type': 'CONSOLE',
        'format': '%d [%l] %m',
        'level': consoleLevel.name,
        'dateFormat': 'HH:mm:ss.SSS',
      });
    }

    await init({'appenders': appenders}, appVersion: appVersion);
    selfLog('Initialized file logger with pattern $filePattern',
        logLevel: Level.INFO);
  }

  /// Initialize with professional file logging (and optional console with pro format)
  static Future<void> initProFile({
    required String filePattern,
    Level fileLevel = Level.DEBUG,
    Level? consoleLevel,
    String path = '',
    bool includeIds = false,
  }) async {
    await _initializeIdentificationAsync();

    // Pro format with or without IDs
    final String fileFormat = includeIds
        ? '[%d][%did][%sid][%i][%l][%c] %m [%f]'
        : '[%d][%i][%l][%c] %m [%f]';

    final String consoleFormat =
        includeIds ? '[%d][%did][%sid][%i][%l][%c] %m' : '[%d][%i][%l][%c] %m';

    final appenders = <Map<String, dynamic>>[];

    // Add file appender with pro format
    appenders.add({
      'type': 'FILE',
      'format': fileFormat,
      'level': fileLevel.name,
      'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      'filePattern': filePattern,
      'fileExtension': 'log',
      'rotationCycle': 'DAY',
      'path': path,
    });

    // Optionally add console appender with pro format
    if (consoleLevel != null) {
      appenders.add({
        'type': 'CONSOLE',
        'format': consoleFormat,
        'level': consoleLevel.name,
        'dateFormat': 'HH:mm:ss.SSS',
      });
    }

    await init({'appenders': appenders});
  }

  /// Initialize professional file logging with app version
  static Future<void> initProFileWithApp({
    required String filePattern,
    required String appVersion,
    Level fileLevel = Level.DEBUG,
    Level consoleLevel = Level.INFO,
    String path = '',
  }) async {
    await _initializeIdentificationAsync();

    final appenders = <Map<String, dynamic>>[];

    // File with full tracking
    appenders.add({
      'type': 'FILE',
      'format': '[%d][%app][%did][%sid][%i][%l][%c] %m [%f]',
      'level': fileLevel.name,
      'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      'filePattern': filePattern,
      'fileExtension': 'log',
      'rotationCycle': 'DAY',
      'path': path,
    });

    // Console with lighter format
    appenders.add({
      'type': 'CONSOLE',
      'format': '[%app][%sid][%l] %m',
      'level': consoleLevel.name,
      'dateFormat': 'HH:mm:ss.SSS',
    });

    await init({'appenders': appenders}, appVersion: appVersion);
  }

  /// Initialize with a preset configuration
  static Future<void> initWithPreset(
    Map<String, dynamic> preset, {
    String? appVersion,
  }) async {
    await init(preset, appVersion: appVersion);
  }

  /// Initialize based on environment (debug/release mode)
  static Future<void> initForEnvironment({
    bool isDebugMode = true,
    String? appVersion,
  }) async {
    final preset =
        isDebugMode ? LoggerPresets.development : LoggerPresets.production;

    await initWithPreset(preset, appVersion: appVersion);
  }

  // ============================================================
  // SYNCHRONOUS INITIALIZATION (Console only)
  // ============================================================

  /// Synchronous initialization - only for console appenders
  static void initSync(
    Map<String, dynamic> config, {
    bool selfDebug = false,
    Level selfLogLevel = Level.INFO,
    String? appVersion,
    int clientProxyCallDepthOffset = 0,
  }) {
    if (!_isConsoleOnly(config)) {
      throw StateError('initSync() only works with console appenders. '
          'Use init() for file/network appenders.');
    }

    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    final requirements = IdProviderResolver.analyzeRequirements(config);
    _deviceIdNeeded = requirements.deviceIdNeeded;
    _sessionIdNeeded = requirements.sessionIdNeeded;
    _fileAppenderNeeded = requirements.fileAppenderNeeded;

    if (_selfDebugEnabled) {
      selfLog(
          IdProviderResolver.getDebugSummary(
            deviceIdNeeded: _deviceIdNeeded,
            sessionIdNeeded: _sessionIdNeeded,
            fileAppenderNeeded: _fileAppenderNeeded,
            getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
          ),
          logLevel: Level.TRACE);
    }

    // FORCE PROVIDER CREATION EARLY - This will trigger validation in resolveProvider()
    // Even for console-only, we need to validate FILE appender requirements
    _idProvider = _createDefaultProvider();

    if (_deviceIdNeeded || _sessionIdNeeded) {
      _initializeIdentification();
    }

    _initialized = true;

    if (appVersion != null) _appVersion = appVersion;

    _parseGlobalLevel(config);

    var appendersFromConfig = <Appender>[];

    for (Map<String, dynamic> app in config['appenders']) {
      final appenderTypeString = app['type']?.toString().toUpperCase();

      if (appenderTypeString != 'CONSOLE') {
        throw StateError('initSync only supports CONSOLE appenders');
      }

      try {
        final appender = ConsoleAppender.fromConfigSync(app);
        appendersFromConfig.add(appender);

        if (selfDebug) {
          selfLog('Created console appender', logLevel: Level.TRACE);
        }
      } catch (e) {
        if (selfDebug) {
          selfLog('Error creating appender: $e', logLevel: Level.ERROR);
        }
        throw ArgumentError('Failed to create console appender: $e');
      }
    }

    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _logAppenderConfigs(appendersFromConfig,
          'Logger initialized sync with ${appendersFromConfig.length} appenders');
    }
  }

  // ============================================================
  // ASYNCHRONOUS INITIALIZATION (All appender types)
  // ============================================================

  /// Full async initialization with all features
  static Future<bool> init(
    Map<String, dynamic>? config, {
    bool test = false,
    DateTime? date,
    int clientProxyCallDepthOffset = 0,
    bool selfDebug = false,
    Level selfLogLevel = Level.INFO,
    String? appVersion,
  }) async {
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    final requirements = IdProviderResolver.analyzeRequirements(config);
    _deviceIdNeeded = requirements.deviceIdNeeded;
    _sessionIdNeeded = requirements.sessionIdNeeded;
    _fileAppenderNeeded = requirements.fileAppenderNeeded;

    if (_selfDebugEnabled) {
      selfLog(
          IdProviderResolver.getDebugSummary(
            deviceIdNeeded: _deviceIdNeeded,
            sessionIdNeeded: _sessionIdNeeded,
            fileAppenderNeeded: _fileAppenderNeeded,
            getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
          ),
          logLevel: Level.TRACE);
    }

    // FORCE PROVIDER CREATION EARLY - This will trigger validation in resolveProvider()
    // Even for console-only, we need to validate FILE appender requirements
    _idProvider = _createDefaultProvider();

    if (_deviceIdNeeded || _sessionIdNeeded) {
      await _initializeIdentificationAsync();
    }

    if (appVersion != null) _appVersion = appVersion;
    _initialized = true;

    if (config == null || config.isEmpty) {
      _rootLogger = Logger.empty();

      if (selfDebug) {
        _setupSelfLogger();
      }

      return true;
    }

    _parseGlobalLevel(config);

    var appendersFromConfig = <Appender>[];
    for (Map<String, dynamic> app in config['appenders']) {
      if (!app.containsKey('type')) {
        throw ArgumentError('Missing type for appender');
      }

      try {
        final appConfig = Map<String, dynamic>.from(app);

        Appender appender = await AppenderRegistry.instance
            .create(appConfig, test: test, date: date);
        appendersFromConfig.add(appender);
      } catch (e) {
        if (selfDebug) {
          selfLog('Error creating appender: $e', logLevel: Level.ERROR);
        }
        throw ArgumentError('Failed to create appender: $e');
      }
    }

    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);

    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _logAppenderConfigs(appendersFromConfig,
          'Logger initialized async with ${appendersFromConfig.length} appenders');
    }

    return true;
  }

  /// Initialize from a configuration file
  static Future<bool> initFromFile(String fileName,
      {bool selfDebug = false, String? appVersion}) async {
    if (selfDebug) {
      print('[SELF_DEBUG] Loading config from file: $fileName');
    }

    var fileContents = File(fileName).readAsStringSync();
    var jsonData = json.decode(fileContents);
    return await init(jsonData, selfDebug: selfDebug, appVersion: appVersion);
  }

  /// Initialize with a pre-built LoggerConfig object
  static Future<void> initWithLoggerConfig(
    LoggerConfig loggerConfig, {
    bool selfDebug = false,
    Level selfLogLevel = Level.INFO,
    String? appVersion,
    int clientProxyCallDepthOffset = 0,
  }) async {
    // Set up self-debugging FIRST
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    // Use the resolver to analyze requirements
    final requirements =
        IdProviderResolver.analyzeRequirements(loggerConfig.appenders);
    _deviceIdNeeded = requirements.deviceIdNeeded;
    _sessionIdNeeded = requirements.sessionIdNeeded;
    _fileAppenderNeeded = requirements.fileAppenderNeeded;

    // Log the one-line summary if debugging
    if (_selfDebugEnabled) {
      selfLog(IdProviderResolver.getDebugSummary(
        deviceIdNeeded: _deviceIdNeeded,
        sessionIdNeeded: _sessionIdNeeded,
        fileAppenderNeeded: _fileAppenderNeeded,
        getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
      ));
    }

    // FORCE PROVIDER CREATION EARLY - This will trigger validation in resolveProvider()
    // Even for console-only, we need to validate FILE appender requirements
    _idProvider = _createDefaultProvider();

    // Initialize identification if needed
    if (_deviceIdNeeded || _sessionIdNeeded) {
      await _initializeIdentificationAsync();
    }

    if (appVersion != null) _appVersion = appVersion;
    _initialized = true;

    // Use the provided appenders
    var appendersFromConfig = loggerConfig.appenders;

    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);

    // Add the root logger to the map
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _logAppenderConfigs(appendersFromConfig,
          'Logger initialized with programmatic LoggerConfig with ${appendersFromConfig.length} active appenders');
    }
  }

  static void _logAppenderConfigs(
      List<Appender> appenders, String initMessage) {
    if (!_selfDebugEnabled) return;

    selfLog(initMessage, logLevel: Level.INFO);

    for (var appender in appenders) {
      selfLog(
          'Appender ${appender.getType()}, ${appender.level}, ${appender.getShortConfigDesc()}',
          logLevel: Level.INFO);
      final config = appender.getConfig();
      config.forEach((key, value) {
        selfLog('--- $key: $value', logLevel: Level.DEBUG);
      });
    }
  }

  // ============================================================
  // DEVICE IDENTIFICATION
  // ============================================================

  static void _initializeIdentification() {
    if (_deviceIdNeeded || _sessionIdNeeded) {
      idProvider.initializeSync();

      // Ensure IDs are set if provider supports them
      if ((idProvider.deviceId == null && _deviceIdNeeded) ||
          (idProvider.sessionId == null && _sessionIdNeeded)) {
        idProvider.regenerateSessionId();
      }
    }
  }

  static Future<void> _initializeIdentificationAsync() async {
    if (_deviceIdNeeded || _sessionIdNeeded) {
      await idProvider.initialize();

      // Ensure IDs are set if provider supports them
      if ((idProvider.deviceId == null && _deviceIdNeeded) ||
          (idProvider.sessionId == null && _sessionIdNeeded)) {
        idProvider.regenerateSessionId();
      }
    }
  }

  // ============================================================
  // BUILDER PATTERN
  // ============================================================

  /// Create a fluent builder for custom configurations
  static LoggerBuilder builder() => LoggerBuilder();

  // ============================================================
  // MDC (MAPPED DIAGNOSTIC CONTEXT) METHODS
  // ============================================================

  /// Set an MDC value
  static void setMdcValue(String key, String value) {
    _mdcContext[key] = value;

    if (_selfDebugEnabled) {
      selfLog('MDC set: $key = $value', logLevel: Level.INFO);
    }
  }

  /// Get an MDC value
  static String? getMdcValue(String key) {
    // Check for special keys that map to system values
    switch (key) {
      case 'did': // Device ID shorthand
        return idProvider.deviceId;
      case 'sid': // Session ID shorthand
        return idProvider.sessionId;
      case 'app': // App version shorthand
        return _appVersion;
      default:
        // Check custom MDC values
        return _mdcContext[key];
    }
  }

  /// Remove an MDC value
  static void removeMdcValue(String key) {
    if (['did', 'sid', 'app'].contains(key)) {
      if (_selfDebugEnabled) {
        selfLog('Cannot remove system key: $key', logLevel: Level.WARN);
      }
      return;
    }

    _mdcContext.remove(key);
    if (_selfDebugEnabled) {
      selfLog('MDC removed: $key', logLevel: Level.INFO);
    }
  }

  /// Clear all custom MDC values
  static void clearMdc() {
    _mdcContext.clear();
    if (_selfDebugEnabled) {
      selfLog('MDC cleared', logLevel: Level.INFO);
    }
  }

  /// Get all MDC values
  static Map<String, String?> getAllMdcValues() {
    return {
      'did': idProvider.deviceId,
      'sid': idProvider.sessionId,
      'app': _appVersion,
      ..._mdcContext,
    };
  }

  // ============================================================
  // APPENDER MANAGEMENT
  // ============================================================

  static void enableAppender(String appenderType) {
    final upperType = appenderType.toUpperCase();
    for (Logger logger in _loggers.values) {
      for (Appender appender in logger.appenders) {
        if (appender.getType() == upperType) {
          appender.setEnabled(true);
          selfLog('Enabled $upperType appender for logger ${logger.name}',
              logLevel: Level.INFO);
          return;
        }
      }
    }
    selfLog('Appender $upperType not found', logLevel: Level.WARN);
  }

  static void disableAppender(String appenderType) {
    final upperType = appenderType.toUpperCase();
    for (Logger logger in _loggers.values) {
      for (Appender appender in logger.appenders) {
        if (appender.getType() == upperType) {
          appender.setEnabled(false);
          selfLog('Disabled $upperType appender for logger ${logger.name}',
              logLevel: Level.INFO);
          return;
        }
      }
    }
    selfLog('Appender $upperType not found', logLevel: Level.WARN);
  }

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  /// Flush all loggers
  static Future<void> flushAll() async {
    selfLog('Flushing all loggers', logLevel: Level.INFO);

    final loggersList = _loggers.values.toList();

    for (var logger in loggersList) {
      try {
        await logger.flush();
      } catch (e) {
        if (_selfDebugEnabled) {
          selfLog('Error flushing logger ${logger.name}: $e',
              logLevel: Level.ERROR);
        }
      }
    }
  }

  /// Dispose and cleanup all resources
  static Future<void> dispose() async {
    final loggersList = _loggers.values.toList();

    for (var logger in loggersList) {
      try {
        await logger.flush();
        await logger.dispose();
      } catch (e) {
        print('[LoggerFactory] Error disposing logger ${logger.name}: $e');
      }
    }

    _loggers.clear();
    _rootLogger = null;
    _selfLogger = null;
    _selfDebugEnabled = false;
    _selfLogLevel = Level.INFO;
    _initialized = false;
    _appVersion = null;
    _mdcContext.clear();
    idProvider.resetSession();
    _idProvider = null;
    AnyLogger.clearCache();
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Get a list of all logger names
  static List<String> getAllLoggerNames() {
    return _loggers.keys.toList();
  }

  /// Log info about all loggers and their appenders
  static void logLogger2AppendersInfo() {
    for (var logger in _loggers.values) {
      for (var appender in logger.appenders) {
        print('Logger: ${logger.name}, Appender: ${appender.getType()}, '
            'Level: ${appender.level}, Format: ${appender.format}, '
            'DateFormat: ${appender.dateFormat}');
      }
    }
  }

  /// Check if configuration only contains console appenders
  static bool _isConsoleOnly(Map<String, dynamic>? config) {
    if (config == null || !config.containsKey('appenders')) return true;

    for (var appender in config['appenders']) {
      if (appender['type']?.toString().toUpperCase() != 'CONSOLE') {
        return false;
      }
    }
    return true;
  }

  /// Parse the most permissive level from all appenders
  static void _parseGlobalLevel(Map<String, dynamic> config) {
    final appenders = config['appenders'] as List<dynamic>?;
    if (appenders != null) {
      Level mostPermissive = Level.OFF;

      for (final appender in appenders) {
        final levelStr = appender['level'] as String?;
        final level = Level.fromString(levelStr) ?? Level.INFO;
        if (level.value < mostPermissive.value) {
          mostPermissive = level;
        }
      }
    }
  }

  // ============================================================
  // SELF-DEBUGGING SUPPORT
  // ============================================================

  /// Set up the self-logging logger
  static void _setupSelfLogger() {
    if (_rootLogger == null) return;

    _selfLogger = Logger.fromExisting(_rootLogger!,
        name: ANYLOGGER_SELF_LOGGER_NAME, consoleOnly: true);
    _selfLogger?.setLevelAll(_selfLogLevel);
    _loggers[ANYLOGGER_SELF_LOGGER_NAME] = _selfLogger!;
    selfLog('Self-debugging enabled', logLevel: Level.INFO);
  }

  /// Log a message using the self logger
  static void selfLog(String message, {Level logLevel = Level.DEBUG}) {
    if (!_selfDebugEnabled) return;

    // If self-logger isn't set up yet, use print for early debugging
    if (_selfLogger == null) {
      print('[ANYLOGGER_STARTUP] $message');
      return;
    }

    switch (logLevel) {
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

  // ============================================================
  // METADATA SETTERS (Public API)
  // ============================================================

  /// Set the application version
  static void setAppVersion(String appVersion) {
    _appVersion = appVersion;
    if (_selfDebugEnabled) {
      selfLog('App version set: $appVersion', logLevel: Level.INFO);
    }
  }

  /// Get the application version
  static String? getAppVersion() => _appVersion;

  /// Get the device ID from the ID provider
  static String? getDeviceId() => idProvider.deviceId;

  /// Get the session ID from the ID provider
  static String? getSessionId() => idProvider.sessionId;

  /// Get the first appender of a specific type
  static T? getFirstAppender<T extends Appender>() {
    if (_rootLogger == null) return null;

    // Check regular appenders first
    for (var appender in _rootLogger!.appenders) {
      if (appender is T) {
        return appender;
      }
    }

    // Then check custom appenders
    for (var appender in _rootLogger!.customAppenders) {
      if (appender is T) {
        return appender;
      }
    }

    return null;
  }

  /// Get all appenders of a specific type
  static List<T> getAllAppenders<T extends Appender>() {
    if (_rootLogger == null) return [];

    final List<T> result = [];

    // Add from regular appenders
    for (var appender in _rootLogger!.appenders) {
      if (appender is T) {
        result.add(appender);
      }
    }

    // Add from custom appenders
    for (var appender in _rootLogger!.customAppenders) {
      if (appender is T) {
        result.add(appender);
      }
    }

    return result;
  }

  /// Get the first appender by type name
  static Appender? getFirstAppenderByType(String type) {
    if (_rootLogger == null) return null;

    final upperType = type.toUpperCase();

    // Check regular appenders first
    for (var appender in _rootLogger!.appenders) {
      if (appender.getType() == upperType) {
        return appender;
      }
    }

    // Then check custom appenders
    for (var appender in _rootLogger!.customAppenders) {
      if (appender.getType() == upperType) {
        return appender;
      }
    }

    return null;
  }

  /// Get all appenders by type name
  static List<Appender> getAllAppendersByType(String type) {
    if (_rootLogger == null) return [];

    final upperType = type.toUpperCase();
    final List<Appender> result = [];

    // Add from regular appenders
    for (var appender in _rootLogger!.appenders) {
      if (appender.getType() == upperType) {
        result.add(appender);
      }
    }

    // Add from custom appenders
    for (var appender in _rootLogger!.customAppenders) {
      if (appender.getType() == upperType) {
        result.add(appender);
      }
    }

    return result;
  }
}
