import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';
import 'package:test/test.dart';

void main() {
  const kAnyLogDartConfig = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%i][%c] %m [%f]',
        'level': 'TRACE',
        'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
      },
    ]
  };

  /**
   * Output:
   *
   * [2025-03-31 16:23:52.251][ANY_DEBUG_LOGGER][LoggerFactory._setupSelfLogger:91] Self-debugging enabled [package:any_logger/src/logger_factory.dart(91:5)]
      [2025-03-31 16:23:52.258][ANY_DEBUG_LOGGER][LoggerFactory.init:77] Logging system initialized with 1 active appenders [package:any_logger/src/logger_factory.dart(77:7)]
      [2025-03-31 16:23:52.259][ANY_DEBUG_LOGGER][new:26] Logger State: Creating new logger named RSC_LOGGER from existing logger: ROOT [package:any_logger/src/logger.dart(26:22)]
      [2025-03-31 16:23:52.259][ANY_DEBUG_LOGGER][LoggerFactory.getLogger:146] Created new logger: RSC_LOGGER [package:any_logger/src/logger_factory.dart(146:9)]
      [2025-03-31 16:23:52.259][RSC_LOGGER][main.<anonymous:22] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_named_loggers.dart(22:12)]
      [2025-03-31 16:23:52.259][RSC_LOGGER][main.<anonymous:22] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_named_loggers.dart(22:12)]
      [2025-03-31 16:23:52.260][ANY_DEBUG_LOGGER][Logger.setFormat:76] Logger State: Setting format for appender CONSOLE to [%i][%d]-->%m<--[Logger.setFormat:76] [package:any_logger/src/logger.dart(76:26)]
      [RSC_LOGGER][2025-03-31 16:23:52.260]-->Doing DEBUG stuff<--[main.<anonymous:29]
      [RSC_LOGGER][2025-03-31 16:23:52.261]-->Doing INFO stuff<--[main.<anonymous:29]
   */
  test('Test1', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);
    var client = Client();

    // should log to RSC_LOGGER logger
    client.doStuff();

    // Create new logger based on ROOT logger
    Logger rscLogger = LoggerFactory.getLogger('RSC_LOGGER');
    rscLogger.setFormat(AppenderType.CONSOLE, '[%i][%d]-->%m<--[%c]');

    // should log to RSC_LOGGER logger
    client.doStuff(); // correct
  });
}

class Client {
  Logger myLogger = LoggerFactory.getLogger('RSC_LOGGER');

  void doStuff() {
    myLogger.logDebug('Doing DEBUG stuff');
    myLogger.logInfo('Doing INFO stuff');
  }
}
