import 'dart:io';

import 'package:any_logger/any_logger_lib.dart';
import 'package:test/test.dart';

void main() {
  group('LoggerFactory Core', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should auto-initialize with defaults when accessing root logger', () {
      final logger = LoggerFactory.getRootLogger();
      expect(logger, isNotNull);
      expect(logger.name, equals(LoggerFactory.ROOT_LOGGER));
    });

    test('should initialize with simple console configuration', () {
      LoggerFactory.initSimpleConsole(level: Level.DEBUG);
      final logger = LoggerFactory.getRootLogger();

      expect(logger.appenders.length, equals(1));
      expect(logger.appenders.first.getType(), equals('CONSOLE'));
      expect(logger.appenders.first.level, equals(Level.DEBUG));
    });

    test('should create named loggers', () {
      LoggerFactory.initSimpleConsole();
      final logger1 = LoggerFactory.getLogger('TestLogger1');
      final logger2 = LoggerFactory.getLogger('TestLogger2');
      final logger1Again = LoggerFactory.getLogger('TestLogger1');

      expect(logger1.name, equals('TestLogger1'));
      expect(logger2.name, equals('TestLogger2'));
      expect(identical(logger1, logger1Again), isTrue, reason: 'Should return the same instance for the same name');
    });

    test('should properly dispose and reset state', () async {
      LoggerFactory.initSimpleConsole();
      final logger = LoggerFactory.getLogger('TestLogger');

      await LoggerFactory.dispose();

      // After disposal, should auto-initialize again
      final newLogger = LoggerFactory.getLogger('TestLogger');
      expect(identical(logger, newLogger), isFalse, reason: 'Should be a new instance after disposal');
    });

    test('should handle configuration from JSON', () async {
      final config = {
        'appenders': [
          {
            'type': 'CONSOLE',
            'format': '[%l] %m',
            'level': 'WARN',
            'dateFormat': 'HH:mm:ss',
          }
        ]
      };

      await LoggerFactory.init(config);
      final logger = LoggerFactory.getRootLogger();

      expect(logger.appenders.length, equals(1));
      expect(logger.appenders.first.level, equals(Level.WARN));
      expect(logger.appenders.first.format, equals('[%l] %m'));
    });
  });

  group('Logger Levels', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should respect log levels', () {
      final messages = <String>[];

      // Create a test appender that captures messages
      LoggerFactory.initSimpleConsole(level: Level.WARN);
      final logger = LoggerFactory.getRootLogger();

      // Mock console output (in real tests, you'd use a custom appender)
      expect(logger.isTraceEnabled, isFalse);
      expect(logger.isDebugEnabled, isFalse);
      expect(logger.isInfoEnabled, isFalse);
      expect(logger.isWarnEnabled, isTrue);
      expect(logger.isErrorEnabled, isTrue);
      expect(logger.isFatalEnabled, isTrue);
    });

    test('should change log levels dynamically', () {
      LoggerFactory.initSimpleConsole(level: Level.ERROR);
      final logger = LoggerFactory.getRootLogger();

      expect(logger.isWarnEnabled, isFalse);

      logger.setLevelAll(Level.DEBUG);

      expect(logger.isWarnEnabled, isTrue);
      expect(logger.isDebugEnabled, isTrue);
    });
  });

  group('LoggerBuilder', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should build console logger with builder', () async {
      await LoggerBuilder().console(level: Level.INFO, format: '[%d] %l: %m', dateFormat: 'HH:mm:ss').build();

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, equals(1));
      expect(logger.appenders.first.getType(), equals('CONSOLE'));
      expect(logger.appenders.first.level, equals(Level.INFO));
    });

    test('should build multiple appenders with builder', () async {
      await LoggerBuilder()
          .console(level: Level.INFO)
          .file(filePattern: 'test_log', level: Level.DEBUG, path: 'logs/')
          .build();

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, equals(2));
      expect(logger.appenders[0].getType(), equals('CONSOLE'));
      expect(logger.appenders[1].getType(), equals('FILE'));
    });

    test('should set MDC values with builder', () async {
      await LoggerBuilder().console(format: '[%X{env}] %m').withMdcValue('env', 'test').withAppVersion('1.0.0').build();

      expect(LoggerFactory.getMdcValue('env'), equals('test'));
      expect(LoggerFactory.appVersion, equals('1.0.0'));
    });

    test('should enable self-debugging with builder', () async {
      await LoggerBuilder().console().withSelfDebug(Level.INFO).build();

      expect(LoggerFactory.selfDebugEnabled, isTrue);
    });
  });

  group('AnyLogger Mixin', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should use default logger name', () {
      LoggerFactory.initSimpleConsole();
      final service = TestServiceDefault();

      expect(service.loggerName, equals(LoggerFactory.ROOT_LOGGER));
      expect(service.logger.name, equals(LoggerFactory.ROOT_LOGGER));
    });

    test('should use custom logger name', () {
      LoggerFactory.initSimpleConsole();
      final service = TestServiceCustom();

      expect(service.loggerName, equals('CustomService'));
      expect(service.logger.name, equals('CustomService'));
    });

    test('should cache logger instances properly', () {
      LoggerFactory.initSimpleConsole();
      final service1 = TestServiceCustom();
      final service2 = TestServiceCustom();

      expect(identical(service1.logger, service2.logger), isTrue, reason: 'Should reuse cached logger for same name');
    });

    test('should clear cache on disposal', () async {
      LoggerFactory.initSimpleConsole();
      final service1 = TestServiceCustom();
      final logger1 = service1.logger;

      await LoggerFactory.dispose();

      LoggerFactory.initSimpleConsole();
      final service2 = TestServiceCustom();
      final logger2 = service2.logger;

      expect(identical(logger1, logger2), isFalse, reason: 'Should have new logger after disposal');
    });
  });

  group('MDC (Mapped Diagnostic Context)', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should set and get MDC values', () async {
      await LoggerFactory.init({
        'appenders': [
          {'type': 'CONSOLE', 'format': '[%X{userId}][%X{requestId}] %m', 'level': 'INFO'}
        ]
      });

      LoggerFactory.setMdcValue('userId', 'user123');
      LoggerFactory.setMdcValue('requestId', 'req456');

      expect(LoggerFactory.getMdcValue('userId'), equals('user123'));
      expect(LoggerFactory.getMdcValue('requestId'), equals('req456'));
    });

    test('should clear MDC values', () {
      LoggerFactory.setMdcValue('test', 'value');
      expect(LoggerFactory.getMdcValue('test'), equals('value'));

      LoggerFactory.removeMdcValue('test');
      expect(LoggerFactory.getMdcValue('test'), isNull);

      LoggerFactory.setMdcValue('test1', 'value1');
      LoggerFactory.setMdcValue('test2', 'value2');
      LoggerFactory.clearMdc();

      expect(LoggerFactory.getMdcValue('test1'), isNull);
      expect(LoggerFactory.getMdcValue('test2'), isNull);
    });
  });

  group('FileAppender', () {
    final testDir = 'test_logs';

    setUp(() async {
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    tearDown(() async {
      await LoggerFactory.dispose();
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should create log file in specified directory', () async {
      await LoggerBuilder().file(filePattern: 'test', path: testDir, level: Level.INFO).build();

      Logger.info('Test message');
      await LoggerFactory.flushAll();

      final dir = Directory(testDir);
      expect(await dir.exists(), isTrue);

      final files = await dir.list().toList();
      expect(files.length, greaterThan(0));

      final logFile = files.first as File;
      final content = await logFile.readAsString();
      expect(content, contains('Test message'));
    });

    test('should handle rotation cycles', () async {
      final now = DateTime.now();
      final dateStr = SimpleDateFormat('yyyy-MM-dd').format(now);

      await LoggerBuilder().file(filePattern: 'daily', path: testDir, level: Level.INFO, rotationCycle: 'DAY').build();

      Logger.info('Daily rotation test');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/daily_$dateStr.log');
      expect(await expectedFile.exists(), isTrue);
    });
  });

  group('AppenderBuilder', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should build console appender', () {
      final appender =
          ConsoleAppenderBuilder().withLevel(Level.WARN).withFormat('[%l] %m').withDateFormat('HH:mm:ss').buildSync();

      expect(appender.getType(), equals('CONSOLE'));
      expect(appender.level, equals(Level.WARN));
      expect(appender.format, equals('[%l] %m'));
      expect(appender.dateFormat, equals('HH:mm:ss'));
    });

    test('should build file appender', () async {
      final appender = await FileAppenderBuilder('test_file')
          .withLevel(Level.DEBUG)
          .withPath('logs/')
          .withRotationCycle(RotationCycle.MONTH)
          .build(test: true); // test mode to avoid actual file creation

      final fileAppender = appender as FileAppender;
      expect(fileAppender.getType(), equals('FILE'));
      expect(fileAppender.level, equals(Level.DEBUG));
      expect(fileAppender.filePattern, equals('test_file'));
      expect(fileAppender.path, equals('logs/'));
      expect(fileAppender.rotationCycle, equals(RotationCycle.MONTH));
    });

    test('should integrate with LoggerBuilder', () async {
      final customAppender = ConsoleAppenderBuilder().withLevel(Level.ERROR).withFormat('ERROR: %m').buildSync();

      await LoggerBuilder().addAppender(customAppender).build();

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, equals(1));
      expect(logger.appenders.first.level, equals(Level.ERROR));
      expect(logger.appenders.first.format, equals('ERROR: %m'));
    });
  });

  group('LogRecord Formatter', () {
    test('should format basic placeholders', () {
      final contextInfo = LoggerStackTrace.from(StackTrace.current);
      final record = LogRecord(Level.INFO, 'Test message', 'TestTag', contextInfo, loggerName: 'TestLogger');

      final formatted = LogRecordFormatter.format(
        record,
        '[%l] %i: %m',
      );

      expect(formatted, equals('[INFO] TestLogger: Test message'));
    });

    test('should format with date', () {
      final contextInfo = LoggerStackTrace.from(StackTrace.current);
      final record = LogRecord(Level.ERROR, 'Error occurred', null, contextInfo, loggerName: 'ErrorLogger');

      final now = DateTime.now();
      record.time = now;

      final formatted = LogRecordFormatter.format(record, '%d - %l: %m', dateFormat: 'HH:mm:ss');

      final expectedTime = SimpleDateFormat('HH:mm:ss').format(now);
      expect(formatted, equals('$expectedTime - ERROR: Error occurred'));
    });

    test('should handle MDC placeholders', () async {
      await LoggerFactory.init({
        'appenders': [
          {'type': 'CONSOLE', 'format': '[%X{env}][%X{version}] %m', 'level': 'INFO'}
        ]
      });

      LoggerFactory.setMdcValue('env', 'production');
      LoggerFactory.setMdcValue('version', '1.2.3');

      final contextInfo = LoggerStackTrace.from(StackTrace.current);
      final record = LogRecord(
        Level.INFO,
        'App started',
        null,
        contextInfo,
      );

      final formatted = LogRecordFormatter.format(record, '[%X{env}][%X{version}] %m');

      expect(formatted, equals('[production][1.2.3] App started'));
    });
  });

  group('Static Logger Methods', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should log using static methods', () {
      LoggerFactory.initSimpleConsole(level: Level.DEBUG);

      // These should not throw
      Logger.trace('Trace message');
      Logger.debug('Debug message');
      Logger.info('Info message');
      Logger.warn('Warning message');
      Logger.error('Error message');
      Logger.fatal('Fatal message');

      expect(Logger.debugEnabled, isTrue);
      expect(Logger.infoEnabled, isTrue);
    });

    test('should auto-initialize when using static methods', () {
      // Don't initialize explicitly
      Logger.info('Should auto-initialize');

      final logger = LoggerFactory.getRootLogger();
      expect(logger, isNotNull);
      expect(logger.appenders.length, greaterThan(0));
    });
  });

  group('Error Handling', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should log exceptions with stack traces', () {
      LoggerFactory.initSimpleConsole();

      try {
        throw Exception('Test exception');
      } catch (e, stack) {
        // Should not throw
        Logger.error('An error occurred', exception: e, stackTrace: stack);
      }
    });

    test('should handle null values gracefully', () {
      LoggerFactory.initSimpleConsole();

      // Should not throw with null values
      Logger.info('Message', tag: null);
      Logger.error('Error', exception: null, stackTrace: null);
    });
  });

  group('Performance', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should skip expensive operations when level disabled', () {
      LoggerFactory.initSimpleConsole(level: Level.ERROR);
      final logger = LoggerFactory.getRootLogger();

      var expensiveOperationCalled = false;
      String expensiveOperation() {
        expensiveOperationCalled = true;
        return 'Expensive result';
      }

      // This should not call the expensive operation
      logger.logDebugSupplier(expensiveOperation);

      expect(expensiveOperationCalled, isFalse,
          reason: 'Expensive operation should not be called when debug is disabled');

      // This should call it
      logger.logErrorSupplier(expensiveOperation);

      expect(expensiveOperationCalled, isTrue, reason: 'Expensive operation should be called when error is enabled');
    });
  });

  group('Presets', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should use development preset', () async {
      await LoggerFactory.initWithPreset(LoggerPresets.development);

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, greaterThan(0));
      expect(logger.isDebugEnabled, isTrue);
    });

    test('should use production preset', () async {
      await LoggerFactory.initWithPreset(LoggerPresets.production);

      final logger = LoggerFactory.getRootLogger();
      expect(logger.appenders.length, greaterThan(0));
      // Production preset typically has higher log level
      expect(logger.appenders.first.level.index, greaterThanOrEqualTo(Level.INFO.index));
    });
  });
}

// Test helper classes
class TestServiceDefault with AnyLogger {
  void doWork() {
    logInfo('Working with default logger');
  }
}

class TestServiceCustom with AnyLogger {
  @override
  String get loggerName => 'CustomService';

  void doWork() {
    logInfo('Working with custom logger');
  }
}
