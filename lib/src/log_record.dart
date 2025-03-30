import 'package:intl/intl.dart';

import 'level.dart';
import 'logger_stack_trace.dart';

class LogRecord {
  final Level level;
  final String message;
  final Object? object;
  String? loggerName;
  DateTime time;
  final Object? error;
  final StackTrace? stackTrace;
  final String? tag;
  final String? dateFormat;
  final LoggerStackTrace contextInfo;

  LogRecord(this.level, this.message, this.tag, this.contextInfo,
      {this.error,
      this.stackTrace,
      this.object,
      this.loggerName,
      this.dateFormat})
      : time = DateTime.now();

  @override
  String toString() => '[${level.name}] $tag: $message';

  String getFormattedTime() {
    return DateFormat(dateFormat).format(time);
  }

  String functionNameAndLine() {
    return '${contextInfo.functionName}:${contextInfo.lineNumber}';
  }

  String? inFileLocation() {
    return '${contextInfo.fileName}(${contextInfo.lineNumber}:${contextInfo.columnNumber})';
  }
}
