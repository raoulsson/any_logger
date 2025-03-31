import 'dart:async';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:intl/intl.dart';

import '../any_logger_lib.dart';

class LogRecordFormatter {
  static String format(LogRecord logRecord, String format,
      {String? dateFormat = kDefaultDateFormat}) {
    var fill = '';

    if (format.contains('\%d')) {
      var date = DateFormat(dateFormat).format(logRecord.time);
      format = format.replaceAll('\%d', date);
    }
    if (format.contains('\%t')) {
      if (!StringUtils.isNullOrEmpty(logRecord.tag)) {
        format = format.replaceAll('\%t', logRecord.tag!);
      } else {
        format = format.replaceAll('\%t', '');
      }
    }

    if (format.contains('\%i')) {
      if (StringUtils.isNullOrEmpty(logRecord.loggerName)) {
        format = format.replaceAll('\%i', '');
      } else {
        format = format.replaceAll('\%i', logRecord.loggerName!);
      }
    }
    if (format.contains('\%l')) {
      format = format.replaceAll('\%l', (logRecord.level.name + fill).trim());
    }

    if (format.contains('\%m')) {
      format = format.replaceAll('\%m', eval(logRecord.message));
    }

    if (format.contains('\%c')) {
      var fn = logRecord.functionNameAndLine();
      format = format.replaceAll('\%c', fn);
    }
    if (format.contains('\%f')) {
      var ifl = logRecord.inFileLocation();
      if (ifl != null) {
        format = format.replaceAll('\%f', ifl);
      } else {
        format = format.replaceAll('\%f', '');
      }
    }

    // MDC: https://logging.apache.org/log4j/2.x/manual/thread-context.html
    if (format.contains('\%X')) {
      format.split('%X').forEach((element) {
        if (element.startsWith('{')) {
          var mdcKey = element.substring(1, element.indexOf('}'));
          List<dynamic> values = Zone.current[mdcKey] as List<dynamic>? ?? [];
          if (values.isNotEmpty) {
            format = format.replaceAll('%X{$mdcKey}', values[0].toString());
          } else {
            format = format.replaceAll('%X{$mdcKey}', 'n/a');
          }
        }
      });
    }

    format = format.replaceAll('  ', ' ');
    return format;
  }

  static String formatJson(LogRecord logRecord,
      {String? dateFormat = kDefaultDateFormat}) {
    var map = {
      'time': DateFormat(dateFormat).format(logRecord.time),
      'message': logRecord.message,
      'level': logRecord.level.toString(),
      'tag': logRecord.tag,
    };

    return json.encode(map);
  }

  static String formatEmail(String? template, LogRecord logRecord,
      {String? dateFormat = kDefaultDateFormat}) {
    if (template == null) {
      return formatJson(logRecord, dateFormat: dateFormat);
    }
    return format(logRecord, template);
  }

  static String eval(Object message) {
    if (message is Function()) {
      return message().toString();
    } else if (message is String) {
      return message;
    }
    return message.toString();
  }
}
