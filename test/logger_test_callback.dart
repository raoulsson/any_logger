import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';
import 'package:test/test.dart';

void main() {
  const kAnyLogDartConfig = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%i][%t][%l][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      },
    ]
  };

  test('Test', () async {
    await LoggerFactory.init(kAnyLogDartConfig);
    var client = Client();
    client.doStuff();
  });
}

class Client with AnyLogger {
  void doStuff() {
    logDebug(tag: 'Client', 'Doing stuff');
  }
}
