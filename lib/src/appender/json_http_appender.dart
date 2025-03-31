import 'dart:async';
import 'dart:convert';
import 'package:basic_utils/basic_utils.dart';
import 'package:intl/intl.dart';

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';

class JsonHttpAppender extends Appender {
  String? url;
  String? username;
  String? password;
  Map<String, String> headers = {};
  String? appVersion;

  // Default payload pattern for identification part
  String payloadPatternIdPart = '''
{
  "deviceId": "%X{logging.device-hash}",
  "sessionId": "%X{logging.session-hash}",
  "appVersion": "%APP-VERSION",
''';

  // Default payload pattern for logs part
  String payloadPatternLogsPart = '''
  "logs": [
    {
      "timestamp": "%d",
      "level": "%l",
      "message": "%m",
      "tag": "%t",
      "location": "%f",
      "Class": "%CLASS",
      "Method": "%METHOD",
      "Line": "%LINE"
    }
  ]
}''';

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
    } else {
      // Default Content-Type header if not specified
      headers.putIfAbsent('Content-Type', () => 'application/json');
    }

    if (config.containsKey('username')) {
      username = config['username'];
    }

    if (config.containsKey('password')) {
      password = config['password'];
    }

    // Load custom payload patterns if specified
    if (config.containsKey('payloadPatternIdPart')) {
      payloadPatternIdPart = config['payloadPatternIdPart'];
    }

    if (config.containsKey('payloadPatternLogsPart')) {
      payloadPatternLogsPart = config['payloadPatternLogsPart'];
    }

    // Initialize app version
    _initAppVersion();
  }

  // Initialize app version from package info
  Future<void> _initAppVersion() async {
    if (appVersion != null) return;

    // try {
    //   final packageInfo = await PackageInfo.fromPlatform();
    //   appVersion = packageInfo.version;
    // } catch (e) {
      appVersion = '1.0.0'; // Fallback version
    // }
  }

  @override
  void append(LogRecord logRecord) async {
    if (appVersion == null) {
      await _initAppVersion();
    }

    logRecord.loggerName ??= getType();

    // Format the log record according to the payload pattern
    final formattedLog = _formatLogPayload(logRecord);

    // Add authentication if specified
    Map<String, String> requestHeaders = Map.from(headers);
    if (username != null && password != null) {
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      requestHeaders['Authorization'] = basicAuth;
    }

    // Send the request
    try {
      print('Sending log to HTTP endpoint: $url. Payload: $formattedLog');
      await HttpUtils.postForFullResponse(url!,
          body: formattedLog,
          headers: requestHeaders);
    } catch (e) {
      print('Error sending log to HTTP endpoint: $e');
    }
  }

  String _formatLogPayload(LogRecord logRecord) {
    // Start with the ID part of the payload
    String payload = payloadPatternIdPart;

    // Replace MDC values
    if (payload.contains('%X{logging.device-hash}')) {
      final deviceHash = _getMdcValue('logging.device-hash', 'unknown-device');
      payload = payload.replaceAll('%X{logging.device-hash}', deviceHash);
    }

    if (payload.contains('%X{logging.session-hash}')) {
      final sessionHash = _getMdcValue('logging.session-hash', 'unknown-session');
      payload = payload.replaceAll('%X{logging.session-hash}', sessionHash);
    }

    // Replace app version
    payload = payload.replaceAll('%APP-VERSION', appVersion ?? '1.0.0');

    // Add logs part
    String logEntry = payloadPatternLogsPart;

    // Format timestamp
    logEntry = logEntry.replaceAll('%d', DateFormat(dateFormat).format(logRecord.time));

    // Format level
    logEntry = logEntry.replaceAll('%l', logRecord.level.name);

    // Format message (escape JSON special characters)
    logEntry = logEntry.replaceAll('%m', _escapeJsonString(LogRecordFormatter.eval(logRecord.message)));

    // Format tag
    logEntry = logEntry.replaceAll('%t', logRecord.tag ?? '');

    // Format file location
    logEntry = logEntry.replaceAll('%f', logRecord.inFileLocation() ?? '');

    // Format class, method, line
    logEntry = logEntry.replaceAll('%CLASS', logRecord.className ?? '');
    logEntry = logEntry.replaceAll('%METHOD', logRecord.methodName ?? '');
    logEntry = logEntry.replaceAll('%LINE', (logRecord.lineNumber ?? '').toString());

    // Combine the parts
    payload += logEntry;

    return payload;
  }

  String _getMdcValue(String key, String defaultValue) {
    try {
      if (Zone.current[key] != null) {
        List<dynamic> values = Zone.current[key] as List<dynamic>;
        if (values.isNotEmpty) {
          return values[0].toString();
        }
      }
    } catch (e) {
      // Ignore errors and return default
    }
    return defaultValue;
  }

  // Escape special characters in JSON strings
  String _escapeJsonString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
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