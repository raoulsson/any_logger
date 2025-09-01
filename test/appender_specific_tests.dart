import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleAppender', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should support different console modes', () {
      // stdout mode
      final stdoutAppender = ConsoleAppenderBuilder()
          .withMode(ConsoleLoggerMode.stdout)
          .withLevel(Level.INFO)
          .buildSync();

      expect(stdoutAppender.getType(), equals('CONSOLE'));
      expect((stdoutAppender).mode, equals(ConsoleLoggerMode.stdout));

      // devtools mode
      final devtoolsAppender = ConsoleAppenderBuilder()
          .withMode(ConsoleLoggerMode.devtools)
          .withLevel(Level.DEBUG)
          .buildSync();

      expect((devtoolsAppender).mode, equals(ConsoleLoggerMode.devtools));
    });

    test('should format console output correctly', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%l] %c: %m', level: Level.INFO)
          .build();

      // Test different log levels and messages
      Logger.info('Information message');
      Logger.warn('Warning message');
      Logger.error('Error message');

      expect(LoggerFactory.getRootLogger().appenders.first.format,
          equals('[%l] %c: %m'));
    });
  });

  group('FileAppender Rotation', () {
    const testDir = 'test_rotation_logs';

    setUp(() async {
      final dir = Directory(testDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    });

    tearDown(() async {
      await LoggerFactory.dispose();
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should handle daily rotation', () async {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final appender = await FileAppenderBuilder('daily_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.DAILY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test daily rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/daily_test_$dateStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle weekly rotation', () async {
      final now = DateTime.now();
      final weekNumber = Utils.getCalendarWeek(now);
      final weekStr = '${now.year}-CW$weekNumber';

      final appender = await fileAppenderBuilder('weekly_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.WEEKLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test weekly rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/weekly_test_$weekStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle monthly rotation', () async {
      final now = DateTime.now();
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final appender = await fileAppenderBuilder('monthly_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.MONTHLY)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test monthly rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/monthly_test_$monthStr.log');
      expect(await expectedFile.exists(), isTrue);
    });

    test('should handle no rotation', () async {
      final appender = await FileAppenderBuilder('no_rotation_test')
          .withPath(testDir)
          .withRotationCycle(RotationCycle.NEVER)
          .withLevel(Level.INFO)
          .build();

      await LoggerBuilder().replaceAll().addAppender(appender).build();

      Logger.info('Test no rotation');
      await LoggerFactory.flushAll();

      final expectedFile = File('$testDir/no_rotation_test.log');
      expect(await expectedFile.exists(), isTrue);
    });
  });

  group('Mixed Appenders', () {
    tearDown(() async {
      await LoggerFactory.dispose();

      // Clean up test files
      final dir = Directory('mixed_logs');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should support multiple appender types simultaneously', () async {
      // Use test mode for network appenders
      await LoggerFactory.init(null);
      LoggerFactory.getRootLogger().registerCustomAppender(ConsoleAppender());
      LoggerFactory.getRootLogger().registerCustomAppender(FileAppender());

      final config = {
        'appenders': [
          {'type': 'CONSOLE', 'level': 'INFO'},
          {
            'type': 'FILE',
            'filePattern': 'app',
            'path': 'mixed_logs/',
            'level': 'DEBUG'
          },
        ]
      };

      await LoggerFactory.init(config, test: true);

      final logger = LoggerFactory.getRootLogger();

      expect(logger.appenders.length, equals(2));
      expect(logger.appenders[0].getType(), equals('CONSOLE'));
      expect(logger.appenders[1].getType(), equals('FILE'));

      // Different levels for different appenders
      expect(logger.appenders[0].level, equals(Level.INFO));
      expect(logger.appenders[1].level, equals(Level.DEBUG));

      // The effective minimum level should be DEBUG
      expect(logger.minLevel, equals(Level.DEBUG));
    });

    test('should handle selective appender enabling/disabling', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(level: Level.INFO)
          .file(filePattern: 'test', path: 'mixed_logs/', level: Level.DEBUG)
          .build();

      final logger = LoggerFactory.getRootLogger();

      // Initially both should be enabled
      expect(logger.appenders[0].enabled, isTrue);
      expect(logger.appenders[1].enabled, isTrue);

      // Disable file appender
      LoggerFactory.disableAppender('FILE');
      expect(logger.appenders[1].enabled, isFalse);

      // Re-enable file appender
      LoggerFactory.enableAppender('FILE');
      expect(logger.appenders[1].enabled, isTrue);
    });
  });
}
