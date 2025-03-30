import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

const kAnyLogConfig = {
  'appenders': [
    {
      'type': 'CONSOLE',
      'format': '%d%i%t%l%c %m %f',
      'level': 'TRACE',
      'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      'brackets': true,
      'mode': 'stdout', // see ConsoleLoggerMode
    },
  ]
};

void main() {
  test('Demo', () async {
    await Logger.init(kAnyLogConfig);
    var plainClient = PlainClient();
    plainClient.doStuff();
    var clientWith = ClientWith();
    clientWith.doStuff();
  });
}

class PlainClient {
  void doStuff() {
    Logger.debug(tag: 'tag', 'message');
    Logger.debug('message', tag: 'tag');
  }
}

class ClientWith with AnyLogger {
  void doStuff() {
    logDebug('debug', tag: 'tag');
  }
}
