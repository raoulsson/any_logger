import 'dart:async';
import 'dart:developer' as devtools;

import '../../any_logger.dart';

enum ConsoleLoggerMode { stdout, devtools }

class ConsoleAppender extends Appender {
  static const LOGGER_NAME = 'CONSOLE';

  ConsoleLoggerMode mode = ConsoleLoggerMode.stdout;

  int sequenceNumber = 1;

  ConsoleAppender() : super();

  /// Synchronous factory constructor for console-only initialization
  //  final config = {
  //     'appenders': [
  //       {
  //         'type': 'CONSOLE',
  //         'format': '[%d][%did][%sid][%i][%l][%c] %m',  // %did and %sid are automatic
  //         'level': 'INFO',
  //         'dateFormat': 'HH:mm:ss',
  //       }
  //     ]
  //   };
  factory ConsoleAppender.fromConfigSync(Map<String, dynamic> config) {
    // Create appender with current date
    final appender = ConsoleAppender();

    // Initialize common properties without test/date parameters
    // Since this is sync, we can't pass test/date parameters to initializeCommonProperties
    appender.created = DateTime.now();
    appender.format = config['format'] ?? Appender.defaultFormat;
    appender.initialFormat = appender.format;
    appender.dateFormat = config['dateFormat'] ?? Appender.defaultDateFormat;
    appender.initialDateFormat = appender.dateFormat;

    final levelStr = config['level'] as String?;
    if (levelStr != null) {
      appender.level = Level.fromString(levelStr) ?? Level.INFO;
    }

    if (config.containsKey('depthOffset')) {
      appender.clientDepthOffset = config['depthOffset'];
    }

    if (config.containsKey('enabled')) {
      appender.enabled = config['enabled'];
    }

    // Parse mode
    if (config.containsKey('mode')) {
      if (config['mode'] == 'stdout') {
        appender.mode = ConsoleLoggerMode.stdout;
      } else if (config['mode'] == 'devtools') {
        appender.mode = ConsoleLoggerMode.devtools;
      }
    }
    return appender;
  }

  //  final config = {
  //     'appenders': [
  //       {
  //         'type': 'CONSOLE',
  //         'format': '[%d][%did][%sid][%i][%l][%c] %m',  // %did and %sid are automatic
  //         'level': 'INFO',
  //         'dateFormat': 'HH:mm:ss',
  //       }
  //     ]
  //   };
  ConsoleAppender.fromConfig(Map<String, dynamic> config, {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('mode')) {
      if (config['mode'] == 'stdout') {
        mode = ConsoleLoggerMode.stdout;
      } else if (config['mode'] == 'devtools') {
        mode = ConsoleLoggerMode.devtools;
      }
    }
  }

  @override
  Appender createDeepCopy() {
    ConsoleAppender copy = ConsoleAppender();
    copyBasePropertiesTo(copy); // Use helper
    copy.mode = mode;
    copy.sequenceNumber = sequenceNumber;
    return copy;
  }

  @override
  void append(LogRecord logRecord) {
    logRecord.loggerName ??= getType().toString();

    if (mode == ConsoleLoggerMode.devtools) {
      devtools.log(
        LogRecordFormatter.eval(logRecord.message),
        time: logRecord.time,
        sequenceNumber: sequenceNumber++,
        level: logRecord.level.value,
        name: '${logRecord.tag}',
        zone: Zone.current,
        error: logRecord.error,
        stackTrace: logRecord.stackTrace,
      );
    } else {
      print(LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat));
    }

    var tabs = '\t';
    if (logRecord.error != null) {
      print(tabs + logRecord.error.toString());
      tabs = tabs + tabs;
    }
    if (logRecord.stackTrace != null) {
      print(tabs + logRecord.stackTrace.toString());
    }
  }

  @override
  String toString() {
    return 'ConsoleAppender(mode: $mode, sequenceNumber: $sequenceNumber, level: $level, format: $format, dateFormat: $dateFormat, created: $created, enabled: $enabled)';
  }

  @override
  String getType() {
    return 'CONSOLE';
  }

  @override
  String getShortConfigDesc() {
    return 'mode: $mode';
  }

  @override
  Future<void> dispose() async {
    // No resources to dispose of for ConsoleAppender
  }

  @override
  Future<void> flush() async {
    // No resources to flush for ConsoleAppender
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = super.getConfig();
    config.addAll({
      'mode': mode.toString(),
      'sequenceNumber': sequenceNumber,
    });
    return config;
  }
}
