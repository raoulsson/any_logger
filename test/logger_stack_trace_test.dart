import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';
import 'package:test/test.dart';

void main() {
  const kAnyLogConfig = {
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
    await LoggerFactory.init(kAnyLogConfig);
    ClientWithLogEx().logStuff('this is the message with log ex');
    ClientWithLogEx().logException();

    ClientWithDirectLogger()
        .logStuff('this is the message with original logger');

    await LoggerFactory.init(kAnyLogConfig, clientProxyCallDepthOffset: 1);
    ClientBehindOwnProxy().logStuff('this is the message through proxy');
  });
}

class ClientWithLogEx with AnyLogger {
  void logStuff(String s) {
    logTrace(s, tag: 'tag-512');
    logDebug(s, tag: 'tag-512');
    logInfo(s, tag: 'tag-128');
    logWarn(s, tag: 'tag-100');
    logError(s);
    logFatal(s, tag: 'tag-512');
  }

  void logException() {
    try {
      throw Exception('Something went wrong');
    } on Exception catch (exception, stacktrace) {
      logWarn('my code went south...',
          exception: exception, stackTrace: stacktrace);
      expect(true, true);
    }
  }
}

class ClientLoggingProxyWithLogEx with AnyLogger {
  void logDebugProxy(String notThisLine) {
    logDebug(notThisLine);
  }
}

class ClientBehindOwnProxy {
  final proxy = ClientLoggingProxyWithLogEx();

  void logStuff(String thisLine) {
    // this line should be in log output
    proxy.logDebugProxy(thisLine);
  }
}

class ClientWithDirectLogger {
  void logStuff(String x) {
    Logger.debug(tag: 'Some-Tag', x);
  }
}
