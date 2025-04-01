import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

void main() {
  const kAnyLogDartConfig = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%i][%t][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      },
    ]
  };

  test('Test1', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);
    var client = Client();
    client.doStuff();
  });
}

class Client with AnyLogger {
  void doStuff() {
    logDebug(tag: 'ClientCode', 'Doing stuff');
  }
}
