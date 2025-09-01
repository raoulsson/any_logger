import 'dart:io';

import 'package:any_logger/any_logger.dart';
import 'package:test/test.dart';

void main() {
  group('Test Isolation', () {
    test('should isolate state between tests - test 1', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%X{test}] %m')
          .withMdcValue('test', 'test1')
          .withSelfDebug()
          .build();

      final service = ServiceWithLogger();
      service.doWork();

      expect(LoggerFactory.getMdcValue('test'), equals('test1'));
      expect(LoggerFactory.selfDebugEnabled, isTrue);

      await LoggerFactory.dispose();
    });

    test('should isolate state between tests - test 2', () async {
      // This test should start fresh, with no contamination from test 1
      expect(LoggerFactory.getMdcValue('test'), isNull,
          reason: 'MDC should be cleared between tests');

      // Self-debug should be off
      await LoggerBuilder().replaceAll().console().build();

      expect(LoggerFactory.selfDebugEnabled, isFalse,
          reason: 'Self-debug should not leak from previous test');

      final service = ServiceWithLogger();
      service.doWork(); // Should get a fresh logger

      await LoggerFactory.dispose();
    });

    test('should clear AnyLogger mixin cache between tests', () async {
      await LoggerBuilder().replaceAll().console().build();

      final service1 = ServiceWithLogger();
      final logger1 = service1.logger;

      await LoggerFactory.dispose();

      // After dispose, the mixin cache should be cleared
      await LoggerBuilder().replaceAll().console().build();

      final service2 = ServiceWithLogger();
      final logger2 = service2.logger;

      expect(identical(logger1, logger2), isFalse,
          reason: 'Should have different logger instances after disposal');

      await LoggerFactory.dispose();
    });
  });

  group('Multiple Named Loggers', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should support multiple services with different loggers', () async {
      await LoggerBuilder().replaceAll().console(level: Level.DEBUG).build();

      final authService = AuthService();
      final dataService = DataService();
      final uiController = UIController();

      // Each service should have its own logger
      expect(authService.loggerName, equals('AuthService'));
      expect(dataService.loggerName, equals('DataService'));
      expect(uiController.loggerName, equals('UIController'));

      // Configure different levels for different loggers
      final authLogger = LoggerFactory.getLogger('AuthService');
      authLogger.setLevelAll(Level.WARN);

      final dataLogger = LoggerFactory.getLogger('DataService');
      dataLogger.setLevelAll(Level.DEBUG);

      // Verify levels are independent
      expect(authLogger.isDebugEnabled, isFalse);
      expect(dataLogger.isDebugEnabled, isTrue);
    });

    test('should maintain logger hierarchy', () async {
      await LoggerBuilder().replaceAll().console(format: '[%i] %m').build();

      final rootLogger = LoggerFactory.getRootLogger();
      final childLogger = LoggerFactory.getLogger('Child');
      final grandchildLogger = LoggerFactory.getLogger('Child.Grandchild');

      expect(rootLogger.name, equals('ROOT_LOGGER'));
      expect(childLogger.name, equals('Child'));
      expect(grandchildLogger.name, equals('Child.Grandchild'));

      // All should share the same appender configuration initially
      expect(childLogger.appenders.length, equals(rootLogger.appenders.length));
      expect(grandchildLogger.appenders.length,
          equals(rootLogger.appenders.length));
    });
  });

  group('Complex Configuration', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should handle multiple appenders with different levels', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(level: Level.INFO, format: 'CONSOLE: %m')
          .file(
              filePattern: 'debug_log',
              level: Level.DEBUG,
              path: 'test_logs/',
              format: 'FILE: [%d] %l: %m')
          .build();

      final logger = LoggerFactory.getRootLogger();

      expect(logger.appenders.length, equals(2));
      expect(logger.appenders[0].level, equals(Level.INFO));
      expect(logger.appenders[1].level, equals(Level.DEBUG));

      // The effective minimum level should be DEBUG
      expect(logger.isDebugEnabled, isTrue);

      // Clean up
      final dir = Directory('test_logs');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should support runtime reconfiguration', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(level: Level.INFO, format: '[%d] %m', dateFormat: 'HH:mm:ss')
          .build();

      final logger = LoggerFactory.getRootLogger();

      // Change format at runtime
      logger.setFormatAll('[%l] >>> %m');
      expect(logger.appenders.first.format, equals('[%l] >>> %m'));

      // Change date format at runtime
      logger.setDateTimeFormatAll('yyyy-MM-dd HH:mm:ss');
      expect(logger.appenders.first.dateFormat, equals('yyyy-MM-dd HH:mm:ss'));

      // Reset to initial configuration
      logger.resetFormatToInitialConfig();
      logger.resetDateTimeFormatToInitialConfig();
      expect(logger.appenders.first.format, equals('[%d] %m'));
      expect(logger.appenders.first.dateFormat, equals('HH:mm:ss'));
    });
  });

  group('Advanced MDC Usage', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should support request context tracking', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%X{userId}][%X{requestId}][%X{endpoint}] %m')
          .build();

      // Simulate handling multiple requests
      await handleRequest('user123', 'req001', '/api/users');
      await handleRequest('user456', 'req002', '/api/products');
      await handleRequest('user789', 'req003', '/api/orders');

      // MDC should be cleared after each request
      expect(LoggerFactory.getMdcValue('userId'), isNull);
      expect(LoggerFactory.getMdcValue('requestId'), isNull);
      expect(LoggerFactory.getMdcValue('endpoint'), isNull);
    });

    test('should handle app version and environment', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%app][%X{env}][%X{region}] %m')
          .withAppVersion('2.1.0')
          .withMdcValue('env', 'staging')
          .withMdcValue('region', 'us-west-2')
          .build();

      expect(LoggerFactory.appVersion, equals('2.1.0'));
      expect(LoggerFactory.getMdcValue('env'), equals('staging'));
      expect(LoggerFactory.getMdcValue('region'), equals('us-west-2'));

      Logger.info('Application started');
    });
  });

  group('Error Recovery', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should handle concurrent logging', () async {
      await LoggerBuilder().replaceAll().console().build();

      final futures = <Future>[];

      // Create multiple concurrent log operations
      for (var i = 0; i < 100; i++) {
        futures.add(Future(() {
          Logger.info('Concurrent message $i');
        }));
      }

      // Should complete without errors
      await Future.wait(futures);
    });
  });

  group('Production Scenarios', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should handle application lifecycle', () async {
      // Application startup
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%did][%sid][%X{env}] %l: %m')
          .file(filePattern: 'app', path: 'logs/', level: Level.DEBUG)
          .withMdcValue('env', 'production')
          .withAppVersion('1.0.0')
          .build();

      final app = Application();

      // Simulate app lifecycle
      await app.initialize();
      await app.start();
      await app.handleUserRequest('user123');
      await app.stop();
      await app.cleanup();

      // Clean up
      final dir = Directory('logs');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('should support microservice architecture', () async {
      await LoggerBuilder()
          .replaceAll()
          .console(format: '[%X{service}][%X{traceId}] %m')
          .withMdcValue('service', 'api-gateway')
          .build();

      // Simulate microservice communication
      final traceId = 'trace-${DateTime.now().millisecondsSinceEpoch}';
      LoggerFactory.setMdcValue('traceId', traceId);

      Logger.info('Request received');

      // Pass trace ID to downstream service
      await callDownstreamService(traceId);

      Logger.info('Request completed');

      LoggerFactory.removeMdcValue('traceId');
    });
  });

  group('Performance Optimizations', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('should use supplier pattern efficiently', () async {
      await LoggerBuilder().replaceAll().console(level: Level.WARN).build();

      final logger = LoggerFactory.getRootLogger();

      var callCount = 0;
      String expensiveComputation() {
        callCount++;
        // Simulate expensive operation
        var result = 0;
        for (var i = 0; i < 1000000; i++) {
          result += i;
        }
        return 'Result: $result';
      }

      // These should NOT execute the expensive computation
      logger.logDebugSupplier(expensiveComputation);
      logger.logInfoSupplier(expensiveComputation);

      expect(callCount, equals(0),
          reason: 'Expensive computation should not run for disabled levels');

      // This SHOULD execute it
      logger.logErrorSupplier(expensiveComputation);

      expect(callCount, equals(1),
          reason: 'Expensive computation should run for enabled levels');
    });

    test('should cache logger instances', () async {
      await LoggerBuilder().replaceAll().console().build();

      // Request the same logger multiple times
      final logger1 = LoggerFactory.getLogger('TestLogger');
      final logger2 = LoggerFactory.getLogger('TestLogger');
      final logger3 = LoggerFactory.getLogger('TestLogger');

      // Should be the same instance
      expect(identical(logger1, logger2), isTrue);
      expect(identical(logger2, logger3), isTrue);

      // Different name should create different instance
      final logger4 = LoggerFactory.getLogger('DifferentLogger');
      expect(identical(logger1, logger4), isFalse);
    });
  });
}

// Helper classes for testing
class ServiceWithLogger with AnyLogger {
  void doWork() {
    logInfo('Service is working');
  }
}

class AuthService with AnyLogger {
  @override
  String get loggerName => 'AuthService';

  Future<void> login(String username) async {
    logInfo('User $username attempting login');
    await Future.delayed(const Duration(milliseconds: 10));
    logInfo('User $username logged in successfully');
  }
}

class DataService with AnyLogger {
  @override
  String get loggerName => 'DataService';

  Future<void> fetchData() async {
    logDebug('Fetching data from database');
    await Future.delayed(const Duration(milliseconds: 10));
    logDebug('Data fetched successfully');
  }
}

class UIController with AnyLogger {
  @override
  String get loggerName => 'UIController';

  void updateUI(String message) {
    logInfo('Updating UI: $message');
  }
}

class Application with AnyLogger {
  @override
  String get loggerName => 'Application';

  Future<void> initialize() async {
    logInfo('Initializing application');
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> start() async {
    logInfo('Starting application');
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> handleUserRequest(String userId) async {
    logDebug('Handling request for user: $userId');
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> stop() async {
    logInfo('Stopping application');
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> cleanup() async {
    logInfo('Cleaning up resources');
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

// Helper functions
Future<void> handleRequest(
    String userId, String requestId, String endpoint) async {
  LoggerFactory.setMdcValue('userId', userId);
  LoggerFactory.setMdcValue('requestId', requestId);
  LoggerFactory.setMdcValue('endpoint', endpoint);

  Logger.info('Processing request');
  await Future.delayed(const Duration(milliseconds: 10));
  Logger.info('Request completed');

  // Clear MDC after request
  LoggerFactory.removeMdcValue('userId');
  LoggerFactory.removeMdcValue('requestId');
  LoggerFactory.removeMdcValue('endpoint');
}

Future<void> callDownstreamService(String traceId) async {
  // Simulate calling another service
  LoggerFactory.setMdcValue('service', 'downstream-service');
  Logger.info('Processing in downstream service');
  await Future.delayed(const Duration(milliseconds: 10));
  LoggerFactory.setMdcValue('service', 'api-gateway');
}
