import 'dart:async';
import 'dart:developer' as devtools;

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';

enum ConsoleLoggerMode { stdout, devtools }

class ConsoleAppender extends Appender {
  static const LOGGER_NAME = 'CONSOLE';

  ConsoleLoggerMode mode = ConsoleLoggerMode.stdout;

  int sequenceNumber = 1;

  ConsoleAppender() : super();

  ConsoleAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
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
      print(LogRecordFormatter.format(logRecord, format,
          dateFormat: dateFormat, brackets: brackets));
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
    return '${getType()} $format $level $lineInfo';
  }

  @override
  String getType() {
    return AppenderType.CONSOLE.name;
  }
}
