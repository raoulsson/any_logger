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

  void doStuff() {
    Logger.debug('Doing DEBUG stuff');
    Logger.info('Doing INFO stuff');
  }

  /***
   * Output:
   *
   * [2025-03-31 16:24:15.114][ANY_DEBUG_LOGGER][LoggerFactory._setupSelfLogger:91] Self-debugging enabled [package:any_logger/src/logger_factory.dart(91:5)]
      [2025-03-31 16:24:15.120][ANY_DEBUG_LOGGER][LoggerFactory.init:77] Logging system initialized with 1 active appenders [package:any_logger/src/logger_factory.dart(77:7)]
      [2025-03-31 16:24:15.120][ROOT][main.doStuff:18] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_static_loggers.dart(18:12)]
      [2025-03-31 16:24:15.121][ROOT][main.doStuff:19] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_static_loggers.dart(19:12)]
      [2025-03-31 16:24:15.121][ANY_DEBUG_LOGGER][new:26] Logger State: Creating new logger named RSC_LOGGER from existing logger: ROOT [package:any_logger/src/logger.dart(26:22)]
      [2025-03-31 16:24:15.121][ANY_DEBUG_LOGGER][LoggerFactory.getLogger:146] Created new logger: RSC_LOGGER [package:any_logger/src/logger_factory.dart(146:9)]
      [2025-03-31 16:24:15.121][ANY_DEBUG_LOGGER][Logger.setLevelAll:93] Logger State: Setting level for all appenders to WARN [package:any_logger/src/logger.dart(93:11)]
      [2025-03-31 16:24:15.121][ROOT][main.doStuff:18] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_static_loggers.dart(18:12)]
      [2025-03-31 16:24:15.121][ROOT][main.doStuff:19] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_static_loggers.dart(19:12)]
   */
  test('Test1', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);

    // should log to ROOT logger
    doStuff();

    // Create new logger based on ROOT logger
    Logger rscLogger = LoggerFactory.getLogger('RSC_LOGGER');
    rscLogger.setLevelAll(Level.WARN);

    // should log to ROOT logger
    doStuff(); // correct
  });
}
