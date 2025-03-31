import 'package:basic_utils/basic_utils.dart';

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';

class JsonHttpAppender extends Appender {
  String? url;

  Map<String, String> headers = {};

  JsonHttpAppender() : super();

  JsonHttpAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('url')) {
      url = config['url'];
    } else {
      throw ArgumentError('Missing url argument for JsonHttpAppender');
    }

    if (config.containsKey('headers')) {
      List<String> h = config['headers'];
      for (var s in h) {
        var splitted = s.split(':');
        headers.putIfAbsent(splitted.elementAt(0), () => splitted.elementAt(1));
      }
    }
  }

  @override
  void append(LogRecord logRecord) {
    logRecord.loggerName ??= getType().toString();
    var body = LogRecordFormatter.formatJson(logRecord, dateFormat: dateFormat);
    HttpUtils.postForFullResponse(url!, body: body, headers: headers);
  }

  @override
  String toString() {
    return '${getType()} $url $level';
  }

  @override
  String getType() {
    return AppenderType.JSON_HTTP.name;
  }
}
