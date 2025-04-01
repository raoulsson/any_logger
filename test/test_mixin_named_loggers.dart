import 'package:any_logger/any_logger_lib.dart';
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
   * [2025-03-31 16:25:00.851][ANY_DEBUG_LOGGER][LoggerFactory._setupSelfLogger:91] Self-debugging enabled [package:any_logger/src/logger_factory.dart(91:5)]
      [2025-03-31 16:25:00.857][ANY_DEBUG_LOGGER][LoggerFactory.init:77] Logging system initialized with 1 active appenders [package:any_logger/src/logger_factory.dart(77:7)]
      [2025-03-31 16:25:00.858][ROOT][ClientWithAnyLoggerMixin.doStuff:98] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(98:5)]
      [2025-03-31 16:25:00.858][ROOT][ClientWithAnyLoggerMixin.doStuff:99] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(99:5)]
      [2025-03-31 16:25:00.858][ANY_DEBUG_LOGGER][new:26] Logger State: Creating new logger named RSC_LOGGER from existing logger: ROOT [package:any_logger/src/logger.dart(26:22)]
      [2025-03-31 16:25:00.859][ANY_DEBUG_LOGGER][LoggerFactory.getLogger:146] Created new logger: RSC_LOGGER [package:any_logger/src/logger_factory.dart(146:9)]
      [2025-03-31 16:25:00.859][ANY_DEBUG_LOGGER][Logger.setLevelAll:93] Logger State: Setting level for all appenders to WARN [package:any_logger/src/logger.dart(93:11)]
      [2025-03-31 16:25:00.859][ROOT][ClientWithAnyLoggerMixin.doStuff:98] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(98:5)]
      [2025-03-31 16:25:00.859][ROOT][ClientWithAnyLoggerMixin.doStuff:99] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(99:5)]
   */
  test('Test1', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);
    var clientWithRootLogger = ClientWithAnyLoggerMixin();

    // should log to ROOT logger
    clientWithRootLogger.doStuff();

    // Create new logger based on ROOT logger
    Logger rscLogger = LoggerFactory.getLogger('RSC_LOGGER');
    rscLogger.setLevelAll(Level.WARN);

    // should log to ROOT logger
    clientWithRootLogger.doStuff(); // correct
  });

  /**
   * Output:
   *
   * Testing started at 16:08 ...
      [2025-03-31 16:08:43.375][ANY_DEBUG_LOGGER][LoggerFactory._setupSelfLogger:91] Self-debugging enabled [package:any_logger/src/logger_factory.dart(91:5)]
      [2025-03-31 16:08:43.380][ANY_DEBUG_LOGGER][LoggerFactory.init:77] Logging system initialized with 1 active appenders [package:any_logger/src/logger_factory.dart(77:7)]
      [2025-03-31 16:08:43.381][ANY_DEBUG_LOGGER][new:25] Logger State: Creating new logger named RSC_LOGGER from existing logger: ROOT [package:any_logger/src/logger.dart(25:22)]
      [2025-03-31 16:08:43.381][ANY_DEBUG_LOGGER][LoggerFactory.getLogger:146] Created new logger: RSC_LOGGER [package:any_logger/src/logger_factory.dart(146:9)]
      [2025-03-31 16:08:43.381][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(77:5)]
      [2025-03-31 16:08:43.381][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(78:5)]
      [2025-03-31 16:08:43.382][ANY_DEBUG_LOGGER][Logger.setLevelAll:88] Logger State: Setting level for all appenders to WARN [package:any_logger/src/logger.dart(88:22)]
      [2025-03-31 16:08:43.382][ANY_DEBUG_LOGGER][Logger.setLevel:97] Logger State: Setting level for appender CONSOLE to DEBUG [package:any_logger/src/logger.dart(97:26)]
      [2025-03-31 16:08:43.382][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(77:5)]
      [2025-03-31 16:08:43.383][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(78:5)]
      [2025-03-31 16:08:43.383][ANY_DEBUG_LOGGER][Logger.setDateTimeFormatAll:104] Logger State: Setting date format for all appenders to MM/dd/yyyy HH:mm:ss [package:any_logger/src/logger.dart(104:22)]
      [03/31/2025 16:08:43][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(77:5)]
      [03/31/2025 16:08:43][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(78:5)]
      [2025-03-31 16:08:43.383][ANY_DEBUG_LOGGER][Logger.setDateTimeFormat:113] Logger State: Setting date format for appender CONSOLE to mm:ss.SSS [package:any_logger/src/logger.dart(113:26)]
      [08:43.383][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(77:5)]
      [08:43.383][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(78:5)]
      [2025-03-31 16:08:43.384][ANY_DEBUG_LOGGER][Logger.setFormatAll:65] Logger State: Setting format for all appenders to [%d][%i] --> %m [package:any_logger/src/logger.dart(65:22)]
      [08:43.384][RSC_LOGGER] --> Doing DEBUG stuff
      [08:43.384][RSC_LOGGER] --> Doing INFO stuff
      [2025-03-31 16:08:43.384][ANY_DEBUG_LOGGER][Logger.setFormat:74] Logger State: Setting format for appender CONSOLE to %m [%d][%l][Logger.setFormat:74][%i] [package:any_logger/src/logger.dart(74:26)]
      Doing DEBUG stuff [08:43.384][DEBUG][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77][RSC_LOGGER]
      Doing INFO stuff [08:43.384][INFO][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78][RSC_LOGGER]
      [2025-03-31 16:08:43.384][ANY_DEBUG_LOGGER][Logger.resetFormatToInitialConfig:81] Logger State: Resetting format for all appenders to initial config [package:any_logger/src/logger.dart(81:22)]
      [2025-03-31 16:08:43.384][ANY_DEBUG_LOGGER][Logger.resetDateTimeFormatToInitialConfig:120] Logger State: Resetting date format for all appenders to initial config [package:any_logger/src/logger.dart(120:22)]
      [2025-03-31 16:08:43.385][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:77] Doing DEBUG stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(77:5)]
      [2025-03-31 16:08:43.385][RSC_LOGGER][ClientWithAnyLoggerMixinUsingRscLogger.doStuff:78] Doing INFO stuff [file:///Users/raoul/dev/any_logger/test/test_mixin_named_loggers.dart(78:5)]
   */
  test('Test2', () async {
    await LoggerFactory.init(kAnyLogDartConfig, selfDebug: true);
    var clientWithRscLogger = ClientWithAnyLoggerMixinUsingRscLogger();

    // should log to RSC_LOGGER logger
    clientWithRscLogger.doStuff();

    // Create new logger based on ROOT logger
    Logger rscLogger = LoggerFactory.getLogger('RSC_LOGGER');
    rscLogger.setLevelAll(Level.WARN);

    // should not log
    clientWithRscLogger.doStuff(); // correct

    rscLogger.setLevel(AppenderType.CONSOLE, Level.DEBUG);
    clientWithRscLogger.doStuff();
    rscLogger.setDateTimeFormatAll('MM/dd/yyyy HH:mm:ss');
    clientWithRscLogger.doStuff();
    rscLogger.setDateTimeFormat(AppenderType.CONSOLE, 'mm:ss.SSS');
    clientWithRscLogger.doStuff();
    rscLogger.setFormatAll('[%d][%i] --> %m');
    clientWithRscLogger.doStuff();
    rscLogger.setFormat(AppenderType.CONSOLE, '%m [%d][%l][%c][%i]');
    clientWithRscLogger.doStuff();
    rscLogger.resetFormatToInitialConfig();
    rscLogger.resetDateTimeFormatToInitialConfig();
    clientWithRscLogger.doStuff();
  });
}

class ClientWithAnyLoggerMixin with AnyLogger {
  void doStuff() {
    logDebug('Doing DEBUG stuff');
    logInfo('Doing INFO stuff');
  }
}

class ClientWithAnyLoggerMixinUsingRscLogger with AnyLogger {
  @override
  String get loggerName => 'RSC_LOGGER';

  void doStuff() {
    logDebug('Doing DEBUG stuff');
    logInfo('Doing INFO stuff');
  }
}
