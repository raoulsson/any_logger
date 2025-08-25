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
      // Auto-initialize with sensible defaults
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
      // Auto-initialize with sensible defaults
      initSimpleConsole();
    }

    return _loggers.putIfAbsent(name, () {
      if (_rootLogger == null) {
        throw StateError('Root logger not initialized');
      }

      final newLogger = Logger.fromExisting(_rootLogger!, name: name);

      if (_selfDebugEnabled) {
        _selfLog('Created new logger: $name');
      }

      return newLogger;
    });
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

    // Add file appender
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

    // Optionally add console appender
    if (consoleLevel != null) {
      appenders.add({
        'type': 'CONSOLE',
        'format': '%d [%l] %m',
        'level': consoleLevel.name,
        'dateFormat': 'HH:mm:ss.SSS',
      });
    }

    await init({'appenders': appenders}, appVersion: appVersion);
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
    // Validate it's console-only
    if (!_isConsoleOnly(config)) {
      throw StateError('initSync() only works with console appenders. '
          'Use init() for file/network appenders.');
    }

    // Set up self-debugging FIRST
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    // Use the resolver to analyze requirements
    final requirements = IdProviderResolver.analyzeRequirements(config);
    _deviceIdNeeded = requirements.deviceIdNeeded;
    _sessionIdNeeded = requirements.sessionIdNeeded;

    // Log the one-line summary if debugging
    if (_selfDebugEnabled) {
      _selfLog(IdProviderResolver.getDebugSummary(
        deviceIdNeeded: _deviceIdNeeded,
        sessionIdNeeded: _sessionIdNeeded,
        getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
      ));
    }

    // Initialize identification synchronously if needed
    if (_deviceIdNeeded || _sessionIdNeeded) {
      _initializeIdentification();
    }

    _initialized = true;

    // Set metadata
    if (appVersion != null) _appVersion = appVersion;

    // Parse global level
    _parseGlobalLevel(config);

    // Create appenders synchronously
    var appendersFromConfig = <Appender>[];

    for (Map<String, dynamic> app in config['appenders']) {
      final appenderTypeString = app['type']?.toString().toUpperCase();

      if (appenderTypeString != 'CONSOLE') {
        throw StateError('initSync only supports CONSOLE appenders');
      }

      try {
        // Use the synchronous factory
        final appender = ConsoleAppender.fromConfigSync(app);
        appendersFromConfig.add(appender);

        if (selfDebug) {
          _selfLog('Initialized console appender: ${appender.toString()}');
        }
      } catch (e) {
        if (selfDebug) {
          _selfLog('Error creating appender: $e', level: Level.ERROR);
        }
        throw ArgumentError('Failed to create console appender: $e');
      }
    }

    // Create root logger
    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _selfLog(
          'Logger initialized synchronously with ${appendersFromConfig.length} console appenders');
      for (var appender in appendersFromConfig) {
        _selfLog('Appender: ${appender.getType()}, Level: ${appender.level}, '
            'Format: ${appender.format}, DateFormat: ${appender.dateFormat}');
      }
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
    // Set up self-debugging FIRST
    _selfDebugEnabled = selfDebug;
    _selfLogLevel = selfLogLevel;

    // Use the resolver to analyze requirements
    final requirements = IdProviderResolver.analyzeRequirements(config);
    _deviceIdNeeded = requirements.deviceIdNeeded;
    _sessionIdNeeded = requirements.sessionIdNeeded;

    // Log the one-line summary if debugging
    if (_selfDebugEnabled) {
      _selfLog(IdProviderResolver.getDebugSummary(
        deviceIdNeeded: _deviceIdNeeded,
        sessionIdNeeded: _sessionIdNeeded,
        getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
      ));
    }

    // Initialize device identification only if needed
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

    // Parse global level
    _parseGlobalLevel(config);

    // Create appenders using the registry
    var appendersFromConfig = <Appender>[];
    for (Map<String, dynamic> app in config['appenders']) {
      if (!app.containsKey('type')) {
        throw ArgumentError('Missing type for appender');
      }

      try {
        // DON'T add test and date to config - pass them as parameters
        // Create a copy of the config to avoid modifying the original
        final appConfig = Map<String, dynamic>.from(app);

        // Use the registry to create the appender with test and date as parameters
        Appender appender = await AppenderRegistry.instance
            .create(appConfig, test: test, date: date);
        appendersFromConfig.add(appender);

        if (selfDebug) {
          _selfLog(
              'Initialized appender: ${appender.getType()}. Appender: ${appender.toString()}');
        }
      } catch (e) {
        if (selfDebug) {
          _selfLog('Error creating appender: $e', level: Level.ERROR);
        }
        throw ArgumentError('Failed to create appender: $e');
      }
    }

    _rootLogger = Logger.defaultLogger(appendersFromConfig,
        clientDepthOffset: clientProxyCallDepthOffset);

    // Add the root logger to the map
    _loggers[ROOT_LOGGER] = _rootLogger!;

    if (selfDebug) {
      _setupSelfLogger();
      _selfLog(
          'Logging system initialized with ${appendersFromConfig.length} active appenders');
      for (var appender in appendersFromConfig) {
        _selfLog('Appender: ${appender.getType()}, Level: ${appender.level}, '
            'Format: ${appender.format}, DateFormat: ${appender.dateFormat}');
      }
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

    // Log the one-line summary if debugging
    if (_selfDebugEnabled) {
      _selfLog(IdProviderResolver.getDebugSummary(
        deviceIdNeeded: _deviceIdNeeded,
        sessionIdNeeded: _sessionIdNeeded,
        getAppDocumentsDirectoryFnc: _getAppDocumentsDirectoryFnc,
      ));
    }

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
      _selfLog(
          'Logging system initialized with programmatic LoggerConfig with ${appendersFromConfig.length} active appenders');
      for (var appender in appendersFromConfig) {
        _selfLog('Appender: ${appender.getType()}, Level: ${appender.level}, '
            'Format: ${appender.format}, DateFormat: ${appender.dateFormat}');
      }
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
    // Store custom MDC values
    _mdcContext[key] = value;

    if (_selfDebugEnabled) {
      _selfLog('MDC set: $key = $value');
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
    // Don't allow removing system keys
    if (['did', 'sid', 'app'].contains(key)) {
      if (_selfDebugEnabled) {
        _selfLog('Cannot remove system key: $key', level: Level.WARN);
      }
      return;
    }

    _mdcContext.remove(key);
    if (_selfDebugEnabled) {
      _selfLog('MDC removed: $key');
    }
  }

  /// Clear all custom MDC values
  static void clearMdc() {
    _mdcContext.clear();
    if (_selfDebugEnabled) {
      _selfLog('Custom MDC values cleared');
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
          selfLogger?.logInfo(
              'Appender $upperType enabled for logger ${logger.name}');
          return;
        }
      }
      selfLogger?.logWarn(
          'Appender $upperType not found, cannot enable it for logger ${logger.name}');
    }
  }

  static void disableAppender(String appenderType) {
    final upperType = appenderType.toUpperCase();
    for (Logger logger in _loggers.values) {
      for (Appender appender in logger.appenders) {
        if (appender.getType() == upperType) {
          appender.setEnabled(false);
          selfLogger?.logInfo(
              'Appender $upperType disabled for logger ${logger.name}');
          return;
        }
      }
      selfLogger?.logWarn(
          'Appender $upperType not found, cannot disable it for logger ${logger.name}');
    }
  }

  // ============================================================
  // LIFECYCLE METHODS
  // ============================================================

  /// Flush all loggers
  static Future<void> flushAll() async {
    _selfLog('Flushing all loggers');

    // Create a copy to avoid concurrent modification
    final loggersList = _loggers.values.toList();

    for (var logger in loggersList) {
      try {
        await logger.flush();
      } catch (e) {
        // Log but don't throw - we want to flush as many as possible
        if (_selfDebugEnabled) {
          _selfLog('Error flushing logger ${logger.name}: $e',
              level: Level.ERROR);
        }
      }
    }
  }

  /// Dispose and cleanup all resources
  static Future<void> dispose() async {
    // Create a copy of loggers to avoid concurrent modification
    final loggersList = _loggers.values.toList();

    // Flush and dispose all loggers WITHOUT using self-logger
    // to avoid MDC contamination from previous tests
    for (var logger in loggersList) {
      try {
        await logger.flush();
        await logger.dispose();
      } catch (e) {
        // Use plain print to avoid MDC contamination
        print('[LoggerFactory] Error disposing logger ${logger.name}: $e');
      }
    }

    // Clear all state IMMEDIATELY to prevent any further logging
    _loggers.clear();
    _rootLogger = null;
    _selfLogger = null;
    _selfDebugEnabled = false;
    _selfLogLevel = Level.INFO;
    _initialized = false;

    // Clear metadata
    _appVersion = null;

    // Clear MDC
    _mdcContext.clear();

    // Reset session for ID provider
    idProvider.resetSession();

    // Clear the ID provider reference
    _idProvider = null;

    // IMPORTANT: Clear the AnyLogger mixin cache to prevent stale references
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
    _selfLog('Self-debugging enabled');
  }

  /// Log a message using the self logger
  static void _selfLog(String message, {Level level = Level.DEBUG}) {
    if (!_selfDebugEnabled) return;

    // If self-logger isn't set up yet, use print for early debugging
    if (_selfLogger == null) {
      print('[ANYLOGGER_STARTUP}] $message');
      return;
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

  // ============================================================
  // METADATA SETTERS (Public API)
  // ============================================================

  /// Set the application version
  static void setAppVersion(String appVersion) {
    _appVersion = appVersion;
    if (_selfDebugEnabled) {
      _selfLog('App version set: $appVersion');
    }
  }

  /// Get the application version
  static String? getAppVersion() => _appVersion;

  /// Get the device ID from the ID provider
  static String? getDeviceId() => idProvider.deviceId;

  /// Get the session ID from the ID provider
  static String? getSessionId() => idProvider.sessionId;
}
