import 'package:any_logger/any_logger.dart';
import 'package:test/test.dart';

/// This file contains simple, clear examples that can be used in documentation
/// Each test demonstrates a specific use case in the simplest way possible
void main() {
  group('Quick Start Examples', () {
    tearDown(() async {
      await LoggerFactory.dispose();
    });

    test('Example 1: Zero configuration - just start logging', () {
      // The simplest way to start - no configuration needed!
      Logger.info('Application started');
      Logger.warn('This is a warning');
      Logger.error('An error occurred');

      // That's it! Logs appear in console with default format
    });

    test('Example 2: Basic configuration', () async {
      // Configure with builder pattern
      await LoggerBuilder().console(level: Level.DEBUG, format: '[%d] %l: %m', dateFormat: 'HH:mm:ss').build();

      // Now you can log at different levels
      Logger.debug('Debug information');
      Logger.info('Information message');
      Logger.warn('Warning message');
      Logger.error('Error message');
    });

    test('Example 3: Using the AnyLogger mixin', () async {
      await LoggerBuilder().console(level: Level.DEBUG).build();

      // Create a service that uses the mixin
      final userService = UserService();
      await userService.createUser('alice@example.com');

      final authService = AuthenticationService();
      await authService.authenticate('alice@example.com', 'password123');
    });

    test('Example 4: File logging', () async {
      // Log to both console and file
      await LoggerBuilder()
          .console(level: Level.INFO)
          .file(filePattern: 'myapp', path: 'logs/', level: Level.DEBUG)
          .build();

      Logger.info('This goes to both console and file');
      Logger.debug('This only goes to file (console is INFO+)');

      await LoggerFactory.flushAll(); // Ensure file is written
    });

    test('Example 5: MDC for context tracking', () async {
      // Configure to show MDC values in log format
      await LoggerBuilder().console(format: '[%X{userId}][%X{requestId}] %l: %m').build();

      // Set context for current operation
      LoggerFactory.setMdcValue('userId', 'user123');
      LoggerFactory.setMdcValue('requestId', 'req-001');

      Logger.info('Processing user request');
      Logger.info('Request completed');

      // Clear context after operation
      LoggerFactory.removeMdcValue('userId');
      LoggerFactory.removeMdcValue('requestId');
    });

    test('Example 6: Production setup with all features', () async {
      await LoggerBuilder()
          // Console for immediate feedback
          .console(level: Level.INFO, format: '[%d][%X{env}][%l] %m')
          // File for detailed debugging
          .file(
              filePattern: 'production',
              path: 'logs/',
              level: Level.DEBUG,
              format: '[%d][%did][%sid][%X{env}][%l][%c] %m [%f]')
          .withAppVersion('1.2.3')
          .withMdcValue('env', 'production')
          .build();

      Logger.info('Application started in production mode');
      Logger.debug('Detailed debug info (file only)');
      Logger.error('Critical error (sent to monitoring)');
    });

    test('Example 7: Performance-aware logging', () async {
      await LoggerBuilder().console(level: Level.INFO).build();

      final logger = LoggerFactory.getRootLogger();

      // Check if level is enabled before expensive operations
      if (logger.isDebugEnabled) {
        final debugInfo = computeExpensiveDebugInfo();
        logger.logDebug(debugInfo);
      }

      // Or use supplier pattern (computation only runs if DEBUG is enabled)
      logger.logDebugSupplier(() => computeExpensiveDebugInfo());
    });

    test('Example 8: Different loggers for different components', () async {
      await LoggerBuilder().console(format: '[%i] %l: %m').build();

      // Each component can have its own logger
      final dbLogger = LoggerFactory.getLogger('Database');
      final apiLogger = LoggerFactory.getLogger('API');
      final uiLogger = LoggerFactory.getLogger('UI');

      // Configure different levels for different components
      dbLogger.setLevelAll(Level.DEBUG);
      apiLogger.setLevelAll(Level.INFO);
      uiLogger.setLevelAll(Level.WARN);

      // Now each component logs at its configured level
      dbLogger.logDebug('SQL query executed');
      apiLogger.logInfo('API request received');
      uiLogger.logWarn('UI rendering slow');
    });

    test('Example 9: Handling errors with stack traces', () async {
      await LoggerBuilder().console().build();

      try {
        // Some operation that might fail
        throw Exception('Something went wrong!');
      } catch (e, stackTrace) {
        Logger.error('Operation failed', exception: e, stackTrace: stackTrace);
      }
    });

    test('Example 10: Using presets', () async {
      // Development preset - detailed logging
      await LoggerFactory.initWithPreset(LoggerPresets.development);
      Logger.debug('Detailed debug information visible in development');

      await LoggerFactory.dispose();

      // Production preset - cleaner output
      await LoggerFactory.initWithPreset(LoggerPresets.production);
      Logger.info('Clean production logging');
    });
  });
}

// Example service classes showing the AnyLogger mixin pattern
class UserService with AnyLogger {
  Future<void> createUser(String email) async {
    logInfo('Creating user: $email');
    // Simulate user creation
    await Future.delayed(const Duration(milliseconds: 100));
    logInfo('User created successfully: $email');
  }

  Future<void> deleteUser(String email) async {
    logWarn('Deleting user: $email');
    // Simulate user deletion
    await Future.delayed(const Duration(milliseconds: 100));
    logInfo('User deleted: $email');
  }
}

class AuthenticationService with AnyLogger {
  @override
  String get loggerName => 'AUTH'; // Custom logger name

  Future<bool> authenticate(String email, String password) async {
    logInfo('Authentication attempt for: $email');

    // Simulate authentication
    await Future.delayed(const Duration(milliseconds: 200));

    if (password == 'password123') {
      logInfo('Authentication successful for: $email');
      return true;
    } else {
      logWarn('Authentication failed for: $email');
      return false;
    }
  }

  Future<void> logout(String email) async {
    logInfo('User logged out: $email');
  }
}

// Helper function for performance example
String computeExpensiveDebugInfo() {
  // Simulate expensive computation
  var result = 0;
  for (var i = 0; i < 1000000; i++) {
    result += i;
  }
  return 'Computed result: $result';
}
