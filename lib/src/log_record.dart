import 'package:intl/intl.dart';

import 'level.dart';
import 'logger_stack_trace.dart';

class LogRecord {
  String? loggerName;
  final String? dateFormat;

  DateTime time;
  final String? tag;
  final Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final LoggerStackTrace contextInfo;
  final String? className;
  final String? methodName;
  final int? lineNumber;

  LogRecord(this.level, this.message, this.tag, this.contextInfo,
      {this.error,
      this.stackTrace,
      this.loggerName,
      this.dateFormat,
      this.className,
      this.methodName,
      this.lineNumber})
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
