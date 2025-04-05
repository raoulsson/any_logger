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
    try {
      final functionName = contextInfo.functionName ?? 'unknown';
      final lineNumber = contextInfo.lineNumber ?? 0;
      return '$functionName:$lineNumber';
    } catch (e) {
      return 'unknown:0';
    }
  }

  String? inFileLocation() {
    try {
      final fileName = contextInfo.fileName ?? 'unknown';
      final lineNumber = contextInfo.lineNumber ?? 0;
      final columnNumber = contextInfo.columnNumber ?? 0;
      return '$fileName($lineNumber:$columnNumber)';
    } catch (e) {
      return 'unknown(0:0)';
    }
  }
}
