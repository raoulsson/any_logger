import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';

class JsonHttpAppender extends Appender {
  String? url;
  String? username;
  String? password;
  Map<String, String> headers = {};
  bool enableCompression = false;
  int maxRetries = 3;

  // Log buffering properties
  final List<Map<String, dynamic>> _logBuffer = [];
  int bufferSize = 100; // Default buffer size
  Timer? _flushTimer;
  Duration flushInterval = Duration(minutes: 1); // Default flush interval

  // Default payload pattern for identification part
  String payloadPatternIdPart = '''
{
  "deviceId": "%X{anylogger.device-hash}",
  "sessionId": "%X{anylogger.session-hash}",
  "appVersion": "%APP-VERSION",
''';

  // Default payload pattern for logs part (modified to handle multiple logs)
  String payloadPatternLogsPart = '''
  "logs": %LOGS_ARRAY%
}''';

  // Default pattern for a single log entry
  String logEntryPattern = '''
{
  "timestamp": "%d",
  "level": "%l",
  "message": "%m",
  "tag": "%t",
  "location": "%f",
  "Class": "%CLASS",
  "Method": "%METHOD",
  "Line": "%LINE"
}''';

  JsonHttpAppender() : super() {
    _startFlushTimer();
  }

  JsonHttpAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('headers')) {
      List<String> h = config['headers'];
      for (var s in h) {
        var parts = s.split(':');
        headers.putIfAbsent(parts.elementAt(0), () => parts.elementAt(1));
      }
    } else {
      // Default Content-Type header if not specified
      headers.putIfAbsent('Content-Type', () => 'application/json');
    }

    if (config.containsKey('url')) {
      url = config['url'];
    } else {
      throw ArgumentError('Missing url argument for JsonHttpAppender');
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

    if (config.containsKey('logEntryPattern')) {
      logEntryPattern = config['logEntryPattern'];
    }

    // Configure buffer settings
    if (config.containsKey('bufferSize')) {
      bufferSize = config['bufferSize'];
    }

    if (config.containsKey('flushIntervalSeconds')) {
      flushInterval = Duration(seconds: config['flushIntervalSeconds']);
    }

    // Start the timer for periodic flushes
    if (!test) {
      _startFlushTimer();
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(flushInterval, (_) {
      Logger.getSelfLogger()?.logInternalState(
          'Periodic flush triggered after ${flushInterval.inSeconds} seconds. Buffer size: ${_logBuffer.length}');
      flush();
    });
  }

  // Initialize app version from package info
  String _getAppVersion() {
    if (LoggerFactory.getAppVersion() != null) {
      return LoggerFactory.getAppVersion()!;
    }
    return '1.0.0'; // Fallback version
  }

  @override
  void append(LogRecord logRecord) async {
    Logger.getSelfLogger()?.logInternalState(
        'Got log record for ${logRecord.loggerName}/${getType()}: ${logRecord.message}');
    // Format the individual log entry
    final formattedLogEntry = _formatLogEntry(logRecord);

    // Add to buffer
    _logBuffer.add(formattedLogEntry);

    // If buffer is full, send the logs
    if (_logBuffer.length >= bufferSize) {
      Logger.getSelfLogger()
          ?.logInternalState('Buffer full: ${_logBuffer.length}');
      await flush();
    }
  }

  /// Formats a single log record into a Map that can be converted to JSON
  Map<String, dynamic> _formatLogEntry(LogRecord logRecord) {
    // Create a map for this log entry based on the pattern
    String entry = logEntryPattern;

    // Format timestamp
    entry =
        entry.replaceAll('%d', DateFormat(dateFormat).format(logRecord.time));

    // Format level
    entry = entry.replaceAll('%l', logRecord.level.name);

    // Format message (escape JSON special characters)
    entry = entry.replaceAll(
        '%m', _escapeJsonString(LogRecordFormatter.eval(logRecord.message)));

    // Format tag
    entry = entry.replaceAll('%t', logRecord.tag ?? '');

    // Format file location
    entry = entry.replaceAll('%f', logRecord.inFileLocation() ?? '');

    // Format class, method, line
    entry = entry.replaceAll('%CLASS', logRecord.className ?? '');
    entry = entry.replaceAll('%METHOD', logRecord.methodName ?? '');
    entry = entry.replaceAll('%LINE', (logRecord.lineNumber ?? '').toString());

    // Parse the JSON string into a Map
    try {
      return json.decode(entry);
    } catch (e) {
      print('Error parsing log entry: $e');
      // Fallback to a simpler format if parsing fails
      return {
        'timestamp': DateFormat(dateFormat).format(logRecord.time),
        'level': logRecord.level.name,
        'message': LogRecordFormatter.eval(logRecord.message),
        'tag': logRecord.tag ?? ''
      };
    }
  }

  /// Flushes the log buffer, sending all accumulated logs
  @override
  Future<void> flush() async {
    if (_logBuffer.isEmpty) return;
    Logger.getSelfLogger()?.logInternalState(
        'Flushing logs to $url. Buffer size: ${_logBuffer.length}');

    // Create a copy of the current buffer and clear it
    final logs = List<Map<String, dynamic>>.from(_logBuffer);
    _logBuffer.clear();

    // Attempt to send with retries
    bool success = await _sendLogsWithRetry(logs);

    // If all retries failed, add logs back to the buffer if there's space
    if (!success && _logBuffer.length + logs.length <= bufferSize * 2) {
      _logBuffer.addAll(logs);
    }
  }

  /// Sends logs with retry mechanism
  Future<bool> _sendLogsWithRetry(List<Map<String, dynamic>> logs) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        await _sendLogs(logs);
        Logger.getSelfLogger()
            ?.logInternalState('Successfully sent logs to $url');
        return true; // Success
      } catch (e) {
        // Log the error but don't rethrow it
        Logger.getSelfLogger()?.logError('Error sending logs to $url: $e',
            tag: 'JsonHttpAppender');

        retryCount++;
        if (retryCount > maxRetries) {
          Logger.getSelfLogger()?.logError(
              'Failed to send logs after $maxRetries retries: $e',
              tag: 'JsonHttpAppender');
          return false; // All retries failed
        }

        // Exponential backoff
        Logger.getSelfLogger()?.logInfo(
            'Retry attempt $retryCount after error: $e',
            tag: 'JsonHttpAppender');
        await Future.delayed(retryDelay);
        retryDelay *= 2; // Double the delay for each retry
      }
    }

    return false; // Should not reach here, but just in case
  }

  /**
   * curl -X POST https://url \
      -u username:password \
      -H "Content-Type: application/json" \
      -d '{
      "deviceId": "device-1800",
      "sessionId": "restart-234",
      "appVersion": "1.0.1",
      "logs": [
      {
      "timestamp": "2025-03-29 18:33:28.042",
      "level": "WARN",
      "message": "Connection lost",
      "tag": "AppLifecycle",
      "location": "package:gemma_app/board/board_connection.dart(366:9)",
      "Class": "BoardConnection",
      "Method": "reStartWebsocket",
      "Line": "366"
      }
      ]
      }'
   */
  Future<void> _sendLogs(List<Map<String, dynamic>> logs) async {
    // Format the complete payload
    String payload = _formatFullPayload(logs);

    Logger.getSelfLogger()?.logInternalState('Sending logs to $url: $payload');

    // Prepare headers
    Map<String, String> requestHeaders = Map.from(headers);
    if (username != null && password != null) {
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      requestHeaders['Authorization'] = basicAuth;
    }

    http.Response response;

    try {
      if (enableCompression) {
        // Compress the payload
        List<int> compressedPayload = gzip.encode(utf8.encode(payload));
        requestHeaders['Content-Encoding'] = 'gzip';

        Logger.getSelfLogger()
            ?.logInternalState('Request headers: $requestHeaders');
        Logger.getSelfLogger()?.logInternalState(
            'Sending compressed payload: ${compressedPayload.length} bytes');

        // Send using http package directly
        response = await http.post(
          Uri.parse(url!),
          headers: requestHeaders,
          body: compressedPayload,
        );
      } else {
        Logger.getSelfLogger()
            ?.logInternalState('Request headers: $requestHeaders');
        Logger.getSelfLogger()?.logInternalState(
            'Sending uncompressed payload: ${payload.length} bytes');
        // Send uncompressed payload
        response = await http.post(
          Uri.parse(url!),
          headers: requestHeaders,
          body: payload,
        );
      }

      Logger.getSelfLogger()?.logInternalState(
          'HTTP response code: ${response.statusCode} ${response.reasonPhrase}');
      Logger.getSelfLogger()?.logInternalState(
          'Response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}...');

      // Check for successful response
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
            'HTTP error: ${response.statusCode} ${response.reasonPhrase} - ${response.body}');
      }
      if (LoggerFactory.onHttpComplete != null) {
        LoggerFactory.onHttpComplete!();
      }
    } catch (e) {
      Logger.getSelfLogger()?.logError('Exception sending logs to $url: $e',
          tag: 'JsonHttpAppender');
      throw e; // Rethrow for the retry mechanism
    }
  }

  /// Formats the complete payload with multiple log entries
  String _formatFullPayload(List<Map<String, dynamic>> logs) {
    // Start with the ID part of the payload
    String payload = payloadPatternIdPart;

    // Replace MDC values
    if (payload.contains('%X{anylogger.device-hash}')) {
      final deviceHash = _getMdcValue('anylogger.device-hash',
          LoggerFactory.getDeviceId() ?? 'anylogger-device-id-not-set');
      payload = payload.replaceAll('%X{anylogger.device-hash}', deviceHash);
    }

    if (payload.contains('%X{anylogger.session-hash}')) {
      final sessionHash = _getMdcValue('anylogger.session-hash',
          LoggerFactory.getSessionId() ?? 'anylogger-session-id-not-set');
      payload = payload.replaceAll('%X{anylogger.session-hash}', sessionHash);
    }

    // Replace app version
    payload = payload.replaceAll('%APP-VERSION', _getAppVersion());

    // Add logs array part
    String logsJsonArray = json.encode(logs);

    String logsPartWithArray =
        payloadPatternLogsPart.replaceAll('%LOGS_ARRAY%', logsJsonArray);

    // Combine the parts
    payload += logsPartWithArray;

    return payload;
  }

  String _getMdcValue(String key, String defaultValue) {
    try {
      if (Zone.current[key] != null) {
        List<dynamic> values = Zone.current[key] as List<dynamic>? ?? [];
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
    return super.toString();
  }

  @override
  String getType() {
    return AppenderType.JSON_HTTP.name;
  }

  /// Disposes resources used by this appender
  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush(); // Flush any remaining logs
  }

  int get bufferCount => _logBuffer.length;

  bool get isBufferFull => _logBuffer.length >= bufferSize;
}
