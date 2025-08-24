// ============================================================
// LoggerBuilder Class
// ============================================================

import '../any_logger.dart';

class LoggerBuilder {
  final List<Map<String, dynamic>> _appenderConfigs = [];
  final List<Appender> _appenders = [];
  final Map<String, String> _mdcValues = {};
  bool _selfDebug = false;
  Level _selfLogLevel = Level.INFO;
  String? _appVersion;
  Level _rootLevel = Level.INFO;

  /// Sets the root logging level for the entire configuration.
  /// This acts as a global filter before messages reach individual appenders.
  /// Defaults to INFO.
  LoggerBuilder withRootLevel(Level level) {
    _rootLevel = level;
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

  /// Add a JSON HTTP appender
  // LoggerBuilder jsonHttp({
  //   required String url,
  //   String? username,
  //   String? password,
  //   Level level = Level.INFO,
  //   int bufferSize = 100,
  //   int flushIntervalSeconds = 60, // 1 minute default
  //   bool enableCompression = false,
  //   Map<String, String>? headers,
  // }) {
  //   final appender = {
  //     'type': 'JSON_HTTP',
  //     'url': url,
  //     'level': level.name,
  //     'bufferSize': bufferSize,
  //     'flushIntervalSeconds': flushIntervalSeconds,
  //     'enableCompression': enableCompression,
  //   };
  //
  //   if (username != null) appender['username'] = username;
  //   if (password != null) appender['password'] = password;
  //   if (headers != null) {
  //     appender['headers'] =
  //         headers.entries.map((e) => '${e.key}:${e.value}').toList();
  //   }
  //
  //   _appenderConfigs.add(appender);
  //   return this;
  // }
  //
  // /// Add an email appender
  // LoggerBuilder email({
  //   required String host,
  //   required List<String> to,
  //   String? user,
  //   String? password,
  //   int? port,
  //   String? fromMail,
  //   String? fromName,
  //   List<String>? toCC,
  //   List<String>? toBCC,
  //   bool ssl = false,
  //   bool html = false,
  //   Level level = Level.INFO,
  //   int batchSize = 10,
  //   int batchIntervalSeconds = 300, // 5 minutes default
  //   Level minLevelForImmediate = Level.ERROR,
  //   String? template,
  //   String? templateFile,
  // }) {
  //   final appender = {
  //     'type': 'EMAIL',
  //     'host': host,
  //     'to': to,
  //     'level': level.name,
  //     'ssl': ssl,
  //     'html': html,
  //     'batchSize': batchSize,
  //     'batchIntervalSeconds': batchIntervalSeconds,
  //     'minLevelForImmediate': minLevelForImmediate.name,
  //   };
  //
  //   if (user != null) appender['user'] = user;
  //   if (password != null) appender['password'] = password;
  //   if (port != null) appender['port'] = port;
  //   if (fromMail != null) appender['fromMail'] = fromMail;
  //   if (fromName != null) appender['fromName'] = fromName;
  //   if (toCC != null) appender['toCC'] = toCC;
  //   if (toBCC != null) appender['toBCC'] = toBCC;
  //   if (template != null) appender['template'] = template;
  //   if (templateFile != null) appender['templateFile'] = templateFile;
  //
  //   _appenderConfigs.add(appender);
  //   return this;
  // }
  //
  // /// Add a MySQL appender
  // LoggerBuilder mysql({
  //   required String host,
  //   required String database,
  //   String? user,
  //   String? password,
  //   int port = 3306,
  //   String table = 'logs',
  //   Level level = Level.INFO,
  //   int batchSize = 50,
  //   int batchIntervalSeconds = 10, // 10 seconds default
  // }) {
  //   final appender = {
  //     'type': 'MYSQL',
  //     'host': host,
  //     'database': database,
  //     'port': port,
  //     'table': table,
  //     'level': level.name,
  //     'batchSize': batchSize,
  //     'batchIntervalSeconds': batchIntervalSeconds,
  //   };
  //
  //   if (user != null) appender['user'] = user;
  //   if (password != null) appender['password'] = password;
  //
  //   _appenderConfigs.add(appender);
  //   return this;
  // }

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
  Future<void> build({bool test = false, DateTime? date}) async {
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

  /// Build synchronously (only works with console appenders)
  void buildSync() {
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
