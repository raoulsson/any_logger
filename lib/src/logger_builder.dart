// ============================================================
// LoggerBuilder Class
// ============================================================

import '../any_logger.dart';

class LoggerBuilder {
  final List<Map<String, dynamic>> _appenderConfigs = [];
  final List<Appender> _appenders = [];
  final Map<String, String> _mdcValues = {};
  bool _selfDebug = false;
  Level _selfLogLevel = Level.TRACE;
  String? _appVersion;
  Level _rootLevel = Level.INFO;

  // Default to additive mode - adds to existing appenders
  bool _replaceExisting = false;

  /// Replace all existing appenders with the ones from this builder
  LoggerBuilder replaceAll() {
    _replaceExisting = true;
    return this;
  }

  /// Add to existing appenders (default behavior)
  LoggerBuilder addToExisting() {
    _replaceExisting = false;
    return this;
  }

  /// Sets the root logging level for the entire configuration.
  /// This acts as a global filter before messages reach individual appenders.
  /// Defaults to INFO.
  LoggerBuilder withRootLevel(Level level) {
    _rootLevel = level;
    return this;
  }

  /// Needed by extensions
  LoggerBuilder addAppenderConfig(Map<String, dynamic> config) {
    _appenderConfigs.add(config);
    return this;
  }

  /// Adds a pre-built appender instance to the configuration.
  /// This is useful for custom appenders or those created programmatically
  /// using the [AppenderBuilder].
  LoggerBuilder addAppender(Appender appender) {
    _appenders.add(appender);
    return this;
  }

  /// Add a console appender
  LoggerBuilder console({
    Level level = Level.INFO,
    String format = '%d %l %m',
    String dateFormat = 'HH:mm:ss.SSS',
    bool devtools = false,
  }) {
    _appenderConfigs.add({
      'type': 'CONSOLE',
      'format': format,
      'level': level.name,
      'dateFormat': dateFormat,
      'mode': devtools ? 'devtools' : 'stdout',
    });
    return this;
  }

  /// Add a file appender
  LoggerBuilder file({
    required String filePattern,
    Level level = Level.DEBUG,
    String format = '%d [%l][%t] %c - %m [%f]',
    String dateFormat = 'yyyy-MM-dd HH:mm:ss.SSS',
    String fileExtension = 'log',
    String rotationCycle = 'DAY',
    String path = '',
  }) {
    _appenderConfigs.add({
      'type': 'FILE',
      'format': format,
      'level': level.name,
      'dateFormat': dateFormat,
      'filePattern': filePattern,
      'fileExtension': fileExtension,
      'rotationCycle': rotationCycle,
      'path': path,
    });
    return this;
  }

  /// Enable self-debugging
  LoggerBuilder withSelfDebug([Level level = Level.DEBUG]) {
    _selfDebug = true;
    _selfLogLevel = level;
    return this;
  }

  /// Set app version
  LoggerBuilder withAppVersion(String appVersion) {
    _appVersion = appVersion;
    return this;
  }

  /// Add a custom MDC value
  LoggerBuilder withMdcValue(String key, String value) {
    _mdcValues[key] = value;
    return this;
  }

  /// Build and initialize the logger asynchronously
  /// By default, ADDS to existing appenders. Use replaceAll() to replace them.
  Future<void> build({bool test = false, DateTime? date}) async {
    _checkIfSetupIsCorrect();

    if (_replaceExisting) {
      // Replace mode - original behavior
      await _buildAndReplace(test: test, date: date);
    } else {
      // Additive mode - new default behavior
      await _addToExistingLogger(test: test, date: date);
    }
  }

  /// Build and replace all existing appenders (original behavior)
  Future<void> _buildAndReplace({bool test = false, DateTime? date}) async {
    // Start with manually added appenders
    final List<Appender> allAppenders = List.from(_appenders);

    // Asynchronously build appenders from their configurations using the registry
    for (final config in _appenderConfigs) {
      try {
        // Pass test and date as parameters, not in config
        final appender = await AppenderRegistry.instance.create(
          config,
          test: test,
          date: date,
        );
        allAppenders.add(appender);
      } catch (e) {
        // Provide helpful error message if extension package is missing
        final type = config['type']?.toString().toUpperCase();
        if (type == 'JSON_HTTP' || type == 'EMAIL' || type == 'MYSQL') {
          throw StateError('Failed to create $type appender. '
              'Make sure you have imported the required extension package:\n'
              '  - For JSON_HTTP: import \'package:any_logger_json_http/any_logger_json_http.dart\';\n'
              '  - For EMAIL: import \'package:any_logger_email/any_logger_email.dart\';\n'
              '  - For MYSQL: import \'package:any_logger_mysql/any_logger_mysql.dart\';\n'
              'Original error: $e');
        }
        rethrow;
      }
    }

    // Create the final configuration object
    final loggerConfig = LoggerConfig(
      appenders: allAppenders,
      level: _rootLevel,
    );

    // Set any custom MDC values before initializing
    _mdcValues.forEach((key, value) {
      LoggerFactory.setMdcValue(key, value);
    });

    // Initialize the factory with the programmatic config
    await LoggerFactory.initWithLoggerConfig(
      loggerConfig,
      selfDebug: _selfDebug,
      selfLogLevel: _selfLogLevel,
      appVersion: _appVersion,
    );
  }

  void _checkIfSetupIsCorrect() {
    // FAIL FAST: Check requirements BEFORE trying to create appenders
    // Analyze what we're about to add
    final pendingAppenders = <Map<String, dynamic>>[];

    // Convert manual appenders to config format for analysis
    for (var appender in _appenders) {
      pendingAppenders.add({
        'type': appender.getType(),
        'format': appender.format,
      });
    }

    // Add config appenders
    pendingAppenders.addAll(_appenderConfigs);

    // Use IdProviderResolver to analyze requirements
    final requirements = IdProviderResolver.analyzeRequirements({
      'appenders': pendingAppenders,
    });

    // Check if we need path_provider for FILE/EMAIL appenders on Flutter
    if (IdProviderResolver.isFlutterApp()) {
      if (requirements.fileAppenderNeeded) {
        // Check if path_provider is configured
        final getAppDocsFn = FileAppender.getAppDocumentsDirectoryFnc;
        if (getAppDocsFn == null) {
          // Fail fast with clear error message
          throw IdProviderResolver.getFileOrEmailAppenderErrorMessage();
        }
      }
    }
  }

  /// Add appenders to existing logger configuration
  Future<void> _addToExistingLogger({bool test = false, DateTime? date}) async {
    // Ensure logger is initialized
    final logger = LoggerFactory.getRootLogger();

    // NOW proceed with adding appenders (existing code continues...)
    // First, add manually created appenders
    for (var appender in _appenders) {
      // Check if this type already exists to warn about duplicates
      final existing = LoggerFactory.getFirstAppenderByType(appender.getType());
      if (existing != null && _selfDebug) {
        LoggerFactory.selfLog(
            'Warning: ${appender.getType()} appender already exists, adding another instance',
            logLevel: Level.WARN);
      }

      logger.addCustomAppender(appender);

      if (_selfDebug) {
        LoggerFactory.selfLog(
            'Added ${appender.getType()} appender via builder (additive mode)',
            logLevel: Level.INFO);
        appender.logConfig();
      }
    }

    // Then, build and add appenders from configurations
    for (final config in _appenderConfigs) {
      try {
        // Check for duplicates before creating
        final type = config['type']?.toString().toUpperCase();
        final existing = LoggerFactory.getFirstAppenderByType(type ?? '');
        if (existing != null && _selfDebug) {
          LoggerFactory.selfLog(
              'Warning: $type appender already exists, adding another instance',
              logLevel: Level.WARN);
        }

        // Create the appender using the registry
        final appender = await AppenderRegistry.instance.create(
          config,
          test: test,
          date: date,
        );

        logger.addCustomAppender(appender);

        if (_selfDebug) {
          LoggerFactory.selfLog(
              'Added $type appender via builder (additive mode)',
              logLevel: Level.INFO);
          appender.logConfig();
        }
      } catch (e) {
        // Provide helpful error message if extension package is missing
        final type = config['type']?.toString().toUpperCase();
        if (type == 'JSON_HTTP' || type == 'EMAIL' || type == 'MYSQL') {
          throw StateError('Failed to create $type appender. '
              'Make sure you have registered the extension:\n'
              '  - For JSON_HTTP: AnyLoggerJsonHttpExtension.register();\n'
              '  - For EMAIL: AnyLoggerEmailExtension.register();\n'
              '  - For MYSQL: AnyLoggerMySqlExtension.register();\n'
              'Original error: $e');
        }
        rethrow;
      }
    }

    // Update app version if provided
    if (_appVersion != null) {
      LoggerFactory.setAppVersion(_appVersion!);
    }

    // Set any custom MDC values
    _mdcValues.forEach((key, value) {
      LoggerFactory.setMdcValue(key, value);
    });

    if (_selfDebug) {
      LoggerFactory.selfLog(
          'LoggerBuilder (additive mode) added ${_appenders.length + _appenderConfigs.length} appenders to existing configuration',
          logLevel: Level.INFO);
    }
  }

  /// Build synchronously (only works with console appenders and replace mode)
  void buildSync() {
    if (!_replaceExisting) {
      throw StateError('buildSync() only works in replace mode. '
          'Use replaceAll().buildSync() or use async build() for additive mode.');
    }

    if (_appenders.isNotEmpty) {
      throw StateError(
          'buildSync() cannot be used when appenders have been added manually with addAppender(). Use build() instead.');
    }
    if (_appenderConfigs.any((a) => a['type'] != 'CONSOLE')) {
      throw StateError('buildSync() only works with console appenders. '
          'Use build() for file/network appenders.');
    }

    final config = {'appenders': _appenderConfigs};
    LoggerFactory.initSync(
      config,
      selfDebug: _selfDebug,
      selfLogLevel: _selfLogLevel,
      appVersion: _appVersion,
    );

    // Set any custom MDC values
    _mdcValues.forEach((key, value) {
      LoggerFactory.setMdcValue(key, value);
    });
  }
}
