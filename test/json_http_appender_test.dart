import 'dart:io';

import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

/**
 * Read credentials from a file named "http_endpoint_credentials.txt" in the root
 * project directory. Format:
 *
 *    url=<your_url>
 *    username=<your_username>
 *    password=<your_password>
 */
void main() {
  String url = "undefined";
  String username = "undefined";
  String password = "undefined";

  File credentialsFile = File('http_endpoint_credentials.txt');
  if(!credentialsFile.existsSync()) {
    throw Exception('Credentials file not found. Please create a file named "http_endpoint_credentials.txt"');
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
        'bufferSize': 1,
        'maxRetries': 1,
        'enableCompression': false,
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'headers': ['Content-Type:application/json'],
      }
    ]
  };

  test('Test1', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);
    ClientWithAnyLoggerMixin client = ClientWithAnyLoggerMixin();

    client.doStuff();

    LoggerFactory.logLogger2AppendersInfo();

    await LoggerFactory.flushAll();

    //await LoggerFactory.dispose();

    sleep(const Duration(seconds: 2));
  });
}

class ClientWithAnyLoggerMixin with AnyLogger {

  void doStuff() {
    logDebug('Doing stuff');
  }
}
