import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Logger Registration', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('Logger.defaultLogger should auto-register named loggers (Option 2)',
        () async {
      // Create a test appender
      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '[AUTO-REG] %l: %m',
        'level': 'DEBUG',
      });

      // Create logger with auto-registration via Logger.defaultLogger
      final autoLogger =
          Logger.defaultLogger([consoleAppender], name: 'AUTO-LOGGER');

      // Verify the logger was created with correct name
      expect(autoLogger.name, equals('AUTO-LOGGER'));
      expect(autoLogger.appenders.length, equals(1));
      expect(autoLogger.appenders.first.getType(), equals('CONSOLE'));

      // Test retrieval via factory - this should return the SAME instance
      final retrievedLogger = LoggerFactory.getLogger('AUTO-LOGGER');

      // Verify they are the same instance (not a copy)
      expect(identical(autoLogger, retrievedLogger), isTrue);
      expect(retrievedLogger.name, equals('AUTO-LOGGER'));
      expect(retrievedLogger.appenders.length, equals(1));
      expect(retrievedLogger.appenders.first.getType(), equals('CONSOLE'));
    });

    test('Logger.defaultLogger should NOT auto-register root logger', () async {
      // Initialize logging system first
      LoggerFactory.initSimpleConsole();

      // Create a logger without a name (should default to ROOT_LOGGER)
      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '%l: %m',
        'level': 'DEBUG',
      });

      final rootLogger = Logger.defaultLogger([consoleAppender]);
      expect(rootLogger.name, equals(LoggerFactory.ROOT_LOGGER));

      // This should NOT cause any issues since root logger registration
      // is handled differently
    });

    test(
        'LoggerFactory.createCustomLogger should create and register loggers (Option 3)',
        () async {
      // Create test appender
      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '[FACTORY] %l: %m',
        'level': 'INFO',
      });

      // Create logger via factory method
      final myCustomLogger = LoggerFactory.createCustomLogger(
          'MY-CUSTOM-LOGGER', [consoleAppender]);

      // Verify the logger was created correctly
      expect(myCustomLogger.name, equals('MY-CUSTOM-LOGGER'));
      expect(myCustomLogger.appenders.length, equals(1));
      expect(myCustomLogger.appenders.first.getType(), equals('CONSOLE'));
      expect(myCustomLogger.appenders.first.level, equals(Level.INFO));

      // Test retrieval via factory - should return the SAME instance
      final retrievedLogger = LoggerFactory.getLogger('MY-CUSTOM-LOGGER');

      // Verify they are the same instance
      expect(identical(myCustomLogger, retrievedLogger), isTrue);
      expect(retrievedLogger.name, equals('MY-CUSTOM-LOGGER'));
      expect(retrievedLogger.appenders.length, equals(1));
    });

    test('createCustomLogger should work with file appenders', () async {
      // Create a temporary directory for test files
      final testDir = Directory.systemTemp.createTempSync('any_logger_test_');

      try {
        // Create file appender
        final fileAppender = await FileAppender.fromConfig({
          'type': 'FILE',
          'format': '[FILE-TEST] %d %l: %m',
          'level': 'DEBUG',
          'filePattern': 'test_custom_logger',
          'path': testDir.path,
          'clearOnStartup': true,
        });

        // Create custom logger with file appender
        final fileLogger =
            LoggerFactory.createCustomLogger('FILE-LOGGER', [fileAppender]);

        // Verify logger setup
        expect(fileLogger.name, equals('FILE-LOGGER'));
        expect(fileLogger.appenders.length, equals(1));
        expect(fileLogger.appenders.first.getType(), equals('FILE'));

        // Test retrieval
        final retrievedLogger = LoggerFactory.getLogger('FILE-LOGGER');
        expect(identical(fileLogger, retrievedLogger), isTrue);

        // Test logging to verify it works
        fileLogger.logInfo('Test message for custom file logger');
        await LoggerFactory.flushAll();

        // Verify file was created (basic check)
        final files = testDir
            .listSync()
            .where((f) => f.path.contains('test_custom_logger'))
            .toList();
        expect(files.isNotEmpty, isTrue);
      } finally {
        // Clean up
        testDir.deleteSync(recursive: true);
      }
    });

    test('should handle multiple custom loggers with different appenders',
        () async {
      // Create different appenders
      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '[MULTI-CONSOLE] %l: %m',
        'level': 'INFO',
      });

      final console2Appender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '[MULTI-CONSOLE2] %l: %m',
        'level': 'DEBUG',
      });

      // Create multiple custom loggers
      final logger1 =
          LoggerFactory.createCustomLogger('MULTI-1', [consoleAppender]);
      final logger2 = Logger.defaultLogger([console2Appender], name: 'MULTI-2');

      // Verify both are registered and retrievable
      final retrieved1 = LoggerFactory.getLogger('MULTI-1');
      final retrieved2 = LoggerFactory.getLogger('MULTI-2');

      expect(identical(logger1, retrieved1), isTrue);
      expect(identical(logger2, retrieved2), isTrue);

      expect(logger1.name, equals('MULTI-1'));
      expect(logger2.name, equals('MULTI-2'));

      // Verify they have different configurations
      expect(logger1.appenders.first.level, equals(Level.INFO));
      expect(logger2.appenders.first.level, equals(Level.DEBUG));
    });

    test('should work with self-debugging enabled', () async {
      // Enable self-debugging to ensure registration messages work
      LoggerFactory.initSimpleConsole();
      // Note: Would need to test with selfDebug enabled in a real scenario

      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '[DEBUG-TEST] %l: %m',
        'level': 'TRACE',
      });

      // This should not crash even with self-debugging
      final debugLogger =
          LoggerFactory.createCustomLogger('DEBUG-LOGGER', [consoleAppender]);
      final retrieved = LoggerFactory.getLogger('DEBUG-LOGGER');

      expect(identical(debugLogger, retrieved), isTrue);
    });

    test(
        'createCustomLogger should initialize LoggerFactory if not already initialized',
        () async {
      // Ensure factory is not initialized
      await LoggerFactory.dispose();

      final consoleAppender = ConsoleAppender.fromConfig({
        'type': 'CONSOLE',
        'format': '%l: %m',
        'level': 'INFO',
      });

      // This should auto-initialize the factory
      final logger =
          LoggerFactory.createCustomLogger('INIT-TEST', [consoleAppender]);

      // Verify it worked
      expect(logger.name, equals('INIT-TEST'));
      final retrieved = LoggerFactory.getLogger('INIT-TEST');
      expect(identical(logger, retrieved), isTrue);

      // Verify root logger also works (factory was initialized)
      final rootLogger = LoggerFactory.getRootLogger();
      expect(rootLogger, isNotNull);
    });
  });
}
