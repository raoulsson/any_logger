import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

void main() {
  const kAnyLogDartConfig = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '%d%i%t%l%c %m %f',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
        'brackets': true,
      },
    ]
  };

  test('Test', () async {
    await Logger.init(kAnyLogDartConfig);
    var client = Client();
    client.doStuff();
  });
}

class Client with AnyLogger {
  void doStuff() {
    logDebug(tag: 'Client', 'Doing stuff');
  }
}
