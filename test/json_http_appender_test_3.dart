import 'dart:async';
import 'dart:io';

import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

/**
 * Flush buffer after 8 seconds
 */
void main() {
  String url = "undefined";
  String username = "undefined";
  String password = "undefined";

  // Read credentials
  File credentialsFile = File('http_endpoint_credentials.txt');
  if (!credentialsFile.existsSync()) {
    throw Exception(
        'Credentials file not found. Please create a file named "http_endpoint_credentials.txt"');
  }
  List<String> lines = credentialsFile.readAsLinesSync();
  for (String line in lines) {
    if (line.startsWith('url=')) {
      url = line.substring(4);
    } else if (line.startsWith('username=')) {
      username = line.substring(9);
    } else if (line.startsWith('password=')) {
      password = line.substring(9);
    }
  }

  final kAnyLogDartConfig = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%i][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      },
      {
        'type': 'JSON_HTTP',
        'level': 'DEBUG',
        'url': url,
        'username': username,
        'password': password,
        'bufferSize': 100,
        'maxRetries': 3,
        'enableCompression': false,
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'headers': ['Content-Type:application/json'],
        'flushIntervalSeconds': 8,
      }
    ]
  };

  test('Test HTTP logging', () async {
    await LoggerFactory.init(kAnyLogDartConfig,
        selfDebug: true,
        deviceId: 'test_device_id',
        sessionId: 'test-3',
        appVersion: '3.1.12');

    // Create a completer to signal when the HTTP operation is done
    final completer = Completer<void>();

    // Register HTTP completion callback
    LoggerFactory.onHttpComplete = () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    };

    // Log a message
    ClientWithAnyLoggerMixin client = ClientWithAnyLoggerMixin();
    client.doStuff();
    client.doStuff();
    client.doStuff();
    client.doStuff();
    client.doStuff();

    // Wait for HTTP completion with timeout
    try {
      await completer.future.timeout(Duration(seconds: 10));
      print("HTTP request completed successfully");
    } catch (e) {
      print("HTTP request timed out after 10 seconds");
    }

    // Additional delay to ensure logs are printed
    await Future.delayed(Duration(milliseconds: 500));
  });
}

class ClientWithAnyLoggerMixin with AnyLogger {
  void doStuff() {
    logDebug('Doing stuff');
  }
}
