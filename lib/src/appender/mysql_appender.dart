import 'package:mysql1/mysql1.dart';

import '../../any_logger_lib.dart';

class MySqlAppender extends Appender {
  String? host;

  String? user;

  String? password;

  int? port;

  String? database;

  String? table;

  MySqlConnection? _connection;
  ConnectionSettings? _connectionSettings;
  bool _initialized = false;

  MySqlAppender() : super();

  MySqlAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('host')) {
      host = config['host'];
    } else {
      throw ArgumentError('Missing host argument for MySqlAppender');
    }

    if (config.containsKey('user')) {
      user = config['user'];
    } else {
      throw ArgumentError('Missing user argument for MySqlAppender');
    }

    if (config.containsKey('password')) {
      password = config['password'];
    }

    if (config.containsKey('port')) {
      port = config['port'];
    } else {
      throw ArgumentError('Missing port argument for MySqlAppender');
    }

    if (config.containsKey('database')) {
      database = config['database'];
    } else {
      throw ArgumentError('Missing database argument for MySqlAppender');
    }

    if (config.containsKey('table')) {
      table = config['table'];
    } else {
      throw ArgumentError('Missing table argument for MySqlAppender');
    }

    if (!test) {
      _connectionSettings = ConnectionSettings(
          host: host!,
          port: port!,
          user: user,
          password: password,
          db: database);
    }
  }

  Future<void> initialize() async {
    if (_connectionSettings != null && !_initialized) {
      _connection = await MySqlConnection.connect(_connectionSettings!);
      _initialized = true;
    }
  }

  @override
  void append(LogRecord logRecord) async {
    if (!_initialized) {
      await initialize();
    }

    logRecord.loggerName ??= getType().toString();

    if (_connection != null) {
      await _connection!.query(
          'insert into $table (tag, level, message, time) values (?, ?, ?, ?)',
          [
            logRecord.tag,
            logRecord.level.name,
            logRecord.message,
            logRecord.time.toUtc()
          ]);
    }
  }

  @override
  String toString() {
    return '${getType()} $host $port $user $level';
  }

  @override
  AppenderType getType() {
    return AppenderType.MYSQL;
  }
}
