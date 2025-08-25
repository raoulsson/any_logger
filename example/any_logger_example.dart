import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:any_logger/any_logger.dart';

void main() async {
  // Start with the simplest examples and progress to more complex ones
  await cleanupExampleFiles();

  // Run examples from the first file
  await runExamples();

  // Run examples from the second file
  await runProfessionalExamples();
}

// ============================================================
// BASIC TO ADVANCED EXAMPLES
// ============================================================

Future<void> runExamples() async {
  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 1: Zero Config - Just Start Logging!    ║');
  print('╚══════════════════════════════════════════════════╝');
  await zeroConfigExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 2: One-Liner Configurations             ║');
  print('╚══════════════════════════════════════════════════╝');
  await oneLineConfigExamples();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 3: Pro Console Configurations           ║');
  print('╚══════════════════════════════════════════════════╝');
  await proConsoleExamples();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 4: Built-in Presets                     ║');
  print('╚══════════════════════════════════════════════════╝');
  await presetExamples();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 5: AnyLogger Mixin for Classes          ║');
  print('╚══════════════════════════════════════════════════╝');
  await mixinExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 6: Performance Optimization             ║');
  print('╚══════════════════════════════════════════════════╝');
  await performanceExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 7: MDC Custom Context Tracking          ║');
  print('╚══════════════════════════════════════════════════╝');
  await mdcExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 8: Custom Builder Configuration         ║');
  print('╚══════════════════════════════════════════════════╝');
  await customBuilderExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 9: Custom device / session id provider ║');
  print('╚══════════════════════════════════════════════════╝');
  await exampleWithCustomIdProvider();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║ Example 10: AppenderBuilder for Granular Control  ║');
  print('╚══════════════════════════════════════════════════╝');
  await appenderBuilderExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 11: Configuration from JSON File        ║');
  print('╚══════════════════════════════════════════════════╝');
  await jsonConfigExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 12: Pro Service with Self Tracking      ║');
  print('╚══════════════════════════════════════════════════╝');
  await proServiceExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 13: Production-Ready Setup              ║');
  print('╚══════════════════════════════════════════════════╝');
  await productionExample();

  await LoggerFactory.dispose();
}

/// Example 1: Zero configuration - just start logging!
///
/// 20:50:17.721 INFO Application started
/// 20:50:17.736 WARN Warning: Low memory
/// 20:50:17.736 ERROR Failed to connect to server
Future<void> zeroConfigExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder().console().build();
  Logger.info('Application started');
  Logger.warn('Warning: Low memory');
  Logger.error('Failed to connect to server');
}

/// Example 2: One-liner configurations for common needs
/// 20:37:56.705 DEBUG Now debug messages are visible
/// 🚀 INFO: Custom format with emoji!
/// 🚀 WARN: Warning with style
Future<void> oneLineConfigExamples() async {
  await LoggerFactory.dispose();
  await LoggerBuilder().console(level: Level.DEBUG).build();
  Logger.debug('Now debug messages are visible');

  await LoggerFactory.dispose();
  await LoggerBuilder().console(format: '🚀 %l: %m').build();
  Logger.info('Custom format with emoji!');
  Logger.warn('Warning with style');

  await LoggerFactory.dispose();
  await LoggerBuilder()
      .file(filePattern: 'myapp', path: 'logs/')
      .console(level: Level.WARN)
      .build();
  Logger.warn('This goes to both file and console');
}

/// Example 3: Pro Console Configurations
///
/// [20:51:14.871][ROOT_LOGGER][INFO][proConsoleExamples:158] Info message with method and line number [package:any_logger/example/any_logger_example.dart(158:10)]
/// [20:51:14.871][ROOT_LOGGER][ERROR][proConsoleExamples:159] Error with complete file location [package:any_logger/example/any_logger_example.dart(159:10)]
/// [20:51:14.872][ROOT_LOGGER][INFO][proConsoleExamples:160] Includes auto-generated device and session IDs [package:any_logger/example/any_logger_example.dart(160:10)]
Future<void> proConsoleExamples() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        format: '[%d][%i][%l][%c] %m [%f]',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .build();
  Logger.info('Info message with method and line number');
  Logger.error('Error with complete file location');
  Logger.info('Includes auto-generated device and session IDs');
}

/// Example 4: Use built-in presets for common scenarios
///
/// [20:55:53.902][f111296f][72c13fcd][ROOT_LOGGER][DEBUG][presetExamples:167] developmentPro mode [package:any_logger/example/any_logger_example.dart(167:10)]
/// [20:55:53][36826b80][INFO] productionPro mode
/// [20:55:53.909][f111296f][a21fecd0][INFO][presetExamples:175] mobileDevelopment mode
Future<void> presetExamples() async {
  await LoggerFactory.dispose();
  await LoggerFactory.initWithPreset(LoggerPresets.developmentPro);
  Logger.debug('developmentPro mode');

  await LoggerFactory.dispose();
  await LoggerFactory.initWithPreset(LoggerPresets.productionPro);
  Logger.info('productionPro mode');

  await LoggerFactory.dispose();
  await LoggerFactory.initWithPreset(LoggerPresets.mobileDevelopment);
  Logger.info('mobileDevelopment mode');
}

/// Example 5: Using AnyLogger mixin in your classes
///
/// 20:55:53.912 INFO Creating user: alice@example.com
/// 20:55:54.023 INFO User created successfully
/// 20:55:54.025 INFO Authentication attempt for: alice@example.com
Future<void> mixinExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder().console(level: Level.DEBUG).build();
  final userService = UserService();
  final authService = AuthService();
  await userService.createUser('alice@example.com');
  await authService.authenticate('alice@example.com', 'password123');
}

/// Example 6: Performance optimization patterns
///
/// [LoggerFactory] Initialized console appender: Appender(type: CONSOLE, level: INFO, format: %d %l %m, dateFormat: HH:mm:ss.SSS, created: 2025-08-24 20:55:54.239989, enabled: true) ConsoleAppender(mode: ConsoleLoggerMode.stdout, sequenceNumber: 1, level: INFO, format: %d %l %m, dateFormat: HH:mm:ss.SSS, created: 2025-08-24 20:55:54.239989, enabled: true)
/// 20:55:54.241 INFO Setting level for all appenders to DEBUG
/// 20:55:54.243 DEBUG Self-debugging enabled
Future<void> performanceExample() async {
  await LoggerFactory.dispose();
  LoggerBuilder().console(level: Level.INFO).withSelfDebug().buildSync();
  final logger = LoggerFactory.getLogger('Performance');
  // This next line will NOT print, because the logger level is INFO
  logger
      .logDebugSupplier(() => 'This expensive computation is never executed.');
}

/// Example 7: Custom MDC for tracking application context
///
/// [production][user-123][req-001] INFO: Request started
/// [production][user-123][req-001] INFO: Request completed
/// [production][user-456][req-002] INFO: Request started
Future<void> mdcExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(format: '[%X{env}][%X{userId}][%X{requestId}] %l: %m')
      .build();
  LoggerFactory.setMdcValue('env', 'production');
  await handleUserRequest('user-123', 'req-001');
  await handleUserRequest('user-456', 'req-002');
}

/// Example 8a: Custom IdProvider
///
/// [f111296f][f742d81d] 20:55:54.251 [INFO] Info - goes to console and file
/// [f111296f][f742d81d] 20:55:54.251 [INFO] Same here
/// [f111296f][f742d81d] 20:55:54.251 [INFO] ...and here
Future<void> customBuilderExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        format: '[%did][%sid] %d [%l] %m',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .file(
        filePattern: 'app',
        path: 'logs/',
        format: '[%did][%sid][%X{env}] %d [%l][%c] %m [%f]',
      )
      .withMdcValue('env', 'staging')
      .withSelfDebug()
      .build();
  Logger.info('Info - goes to console and file');
  Logger.info('Same here');
  Logger.info('...and here');
}

/// Example 9: With custom IdProvider for %did and %sid
///
/// [my-device-id][my-session-id] Using custom ID provider
/// [my-device-id][my-session-id] Device ID: my-device-id
/// [my-device-id][my-session-id] Session ID: my-session-id
Future<void> exampleWithCustomIdProvider() async {
  await LoggerFactory.dispose();

  // Set custom ID provider BEFORE initialization
  LoggerFactory.setIdProvider(MyCustomIdProvider());

  // Initialize with CONSOLE appender so you can see the output
  await LoggerFactory.init({
    'appenders': [
      {
        'type': 'CONSOLE', // Changed to CONSOLE so you can see output
        'format': '[%did][%sid] %m', // Simple format to clearly show IDs
        'level': 'INFO',
      }
    ]
  });

  final logger = LoggerFactory.getLogger('MyApp');
  logger.logInfo('Using custom ID provider'); // Fixed message
  logger.logInfo('Device ID: ${LoggerFactory.deviceId}');
  logger.logInfo('Session ID: ${LoggerFactory.sessionId}');
}

/// Example 10: Using AppenderBuilder for granular control
///
/// [INFO] This info message goes to both console and file.
/// [INFO] And so does this.
/// [INFO] And also this one.
Future<void> appenderBuilderExample() async {
  await LoggerFactory.dispose();
  final fileAppender =
      await fileAppenderBuilder('app_builder_log').withPath('logs/').build();
  final consoleAppender =
      consoleAppenderBuilder().withFormat('[%l] %m').buildSync();
  await LoggerBuilder()
      .addAppender(consoleAppender)
      .addAppender(fileAppender)
      .build();
  Logger.info('This info message goes to both console and file.');
  Logger.info('And so does this.');
  Logger.info('And also this one.');
}

/// Example 11: Loading configuration from JSON file
///
/// [20:55:54.269][f111296f][ff300524][ROOT_LOGGER][INFO][jsonConfigExample:261] Logger configured from JSON with automatic IDs
/// [20:55:54.272][f111296f][ff300524][ROOT_LOGGER][INFO][jsonConfigExample:265] Line two
/// [20:55:54.272][f111296f][ff300524][ROOT_LOGGER][INFO][jsonConfigExample:266] Line three
Future<void> jsonConfigExample() async {
  await LoggerFactory.dispose();
  final configFile = File('logger_config.json');
  final config = {
    'appenders': [
      {
        'type': 'CONSOLE',
        'format': '[%d][%did][%sid][%i][%l][%c] %m',
        'dateFormat': 'HH:mm:ss.SSS',
      }
    ]
  };
  await configFile.writeAsString(json.encode(config));
  await LoggerFactory.initFromFile('logger_config.json', selfDebug: true);
  Logger.info('Logger configured from JSON with automatic IDs');
  if (await configFile.exists()) {
    await configFile.delete();
  }
  Logger.info('Line two');
  Logger.info('Line three');
}

/// Example 12: Pro Service with automatic tracking
///
/// [20:55:54.276][1f953c8b][ErrorProneService][ERROR][ErrorProneService.handleNetworkRequest:610] Network request failed
/// 	SocketException: Connection timeout
/// [20:55:54.277][1f953c8b][ErrorProneService][INFO][ErrorProneService.processUserInput:618] Valid input processed: invalid@data
/// [20:55:54.279][1f953c8b][ROOT_LOGGER][INFO][proServiceExample:282] The end.
Future<void> proServiceExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .file(
        filePattern: 'error_prone_service',
        path: 'logs/',
      )
      .console(format: '[%d][%sid][%i][%l][%c] %m')
      .withSelfDebug()
      .build();
  final service = ErrorProneService();
  await service.handleNetworkRequest();
  await service.processUserInput('invalid@data');
  Logger.info('The end.');
}

/// Example 13: Production-ready setup
///
/// [2025-236-55 20:55:54.280][f111296f][4a6ec577][production][INFO][productionExample:296] Application started in production mode [package:any_logger/example/any_logger_example.dart(296:10)]
/// [2025-236-55 20:55:54.282][f111296f][4a6ec577][production][INFO][productionExample:297] You got deviceId, sessionId, Logger name, Log level... [package:any_logger/example/any_logger_example.dart(297:10)]
/// [2025-236-55 20:55:54.284][f111296f][4a6ec577][production][INFO][productionExample:298] ...and class.method linnumber, and then again actual file with line and column number if available [package:any_logger/example/any_logger_example.dart(298:10)]
Future<void> productionExample() async {
  await LoggerFactory.dispose();
  final consoleAppender = ConsoleAppenderBuilder()
      .withFormat('[%d][%did][%sid][%X{env}][%l][%c] %m [%f]')
      .withDateFormat('yyyy-DD-mm HH:mm:ss.SSS')
      .buildSync();
  await LoggerBuilder()
      .addAppender(consoleAppender)
      .withMdcValue('env', 'production')
      .build();
  Logger.info('Application started in production mode');
  Logger.info('You got deviceId, sessionId, Logger name, Log level...');
  Logger.info(
      '...and class.method linnumber, and then again actual file with line and column number if available');
}

// ============================================================
// PROFESSIONAL SCENARIO EXAMPLES
// ============================================================

Future<void> runProfessionalExamples() async {
  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 14: Professional Production Format      ║');
  print('╚══════════════════════════════════════════════════╝');
  await professionalSetupExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 15: Performance Monitoring              ║');
  print('╚══════════════════════════════════════════════════╝');
  await performanceMonitoringExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║ Example 16: AppenderBuilder Granular Control     ║');
  print('╚══════════════════════════════════════════════════╝');
  await builderWithAppenderBuilderExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 17: Error Tracking & Debugging          ║');
  print('╚══════════════════════════════════════════════════╝');
  await errorTrackingExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 18: App Lifecycle with Self Tracking    ║');
  print('╚══════════════════════════════════════════════════╝');
  await appLifecycleExample();

  print('\n');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Example 19: Multi-Service Architecture          ║');
  print('╚══════════════════════════════════════════════════╝');
  await multiServiceExample();

  await LoggerFactory.dispose();
}

/// Example 14: Professional production-ready format, variation
///
/// [20:55:54.285][f111296f][265db391][ANYLOGGER_SELF_LOGGER][INFO][LoggerFactory._setupSelfLogger:837] Setting level for all appenders to INFO [package:any_logger/src/logger_factory.dart(837:18)]
/// [20:55:54.286][f111296f][265db391][ROOT_LOGGER][INFO][professionalSetupExample:356] Application initialized with automatic ID tracking [package:any_logger/example/any_logger_example.dart(356:10)]
/// [20:55:54.286][f111296f][265db391][ROOT_LOGGER][DEBUG][professionalSetupExample:357] Device ID persists across app restarts [package:any_logger/example/any_logger_example.dart(357:10)]
Future<void> professionalSetupExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        level: Level.DEBUG,
        format: '[%d][%did][%sid][%i][%l][%c] %m [%f]',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .withSelfDebug(Level.INFO)
      .build();
  Logger.info('Application initialized with automatic ID tracking');
  Logger.debug('Device ID persists across app restarts');
  final componentLogger = LoggerFactory.getLogger('AudioController');
  componentLogger.logDebug('Audio system initialized');
  componentLogger.logInfo('Playing background music');
}

/// Example 15: Simulated app lifecycle with automatic tracking
///
/// CONSOLE [INFO]: This info message goes to both console and file.
/// CONSOLE [ERROR]: This error also goes to both appenders.
/// CONSOLE [INFO]: And i am here because three lines look better...
Future<void> appLifecycleExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        level: Level.DEBUG,
        format: '[%d][%did][%sid][%X{env}][%i][%l][%c] %m [%f]',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .withMdcValue('env', 'staging')
      .withSelfDebug()
      .build();
  final app = MyApplication();
  await app.initialize();
  await app.start();
  await app.handleUserAction('button_click');
  await app.stop();
  await app.dispose();
}

/// Example 16: Multi-service architecture
///
/// [2025-08-24T20:55:54.987][f111296f][fc77d2cb][enterprise][AuthService][INFO][AuthenticationService.login:542] Login attempt for user: user@example.com [package:any_logger/example/any_logger_example.dart(542:5)]
/// [2025-08-24T20:55:54.987][f111296f][fc77d2cb][enterprise][AuthService][DEBUG][AuthenticationService.login:543] Validating credentials [package:any_logger/example/any_logger_example.dart(543:5)]
/// [2025-08-24T20:55:55.089][f111296f][fc77d2cb][enterprise][AuthService][DEBUG][AuthenticationService.login:545] Credentials validated successfully [package:any_logger/example/any_logger_example.dart(545:5)]
Future<void> multiServiceExample() async {
  await LoggerFactory.dispose();
  // FIXME: keeps .withSelfDebug() from previous method: appLifecycleExample. All methods should start fresh, atomically, new born
  await LoggerBuilder()
      .console(
        level: Level.DEBUG,
        format: '[%d][%did][%sid][%X{tenant}][%i][%l][%c] %m [%f]',
        dateFormat: 'yyyy-MM-ddTHH:mm:ss.SSS',
      )
      .withMdcValue('tenant', 'enterprise')
      .build();
  final authService = AuthenticationService();
  final dataService = DataService();
  final uiController = UIController();
  await authService.login('user@example.com', 'password');
  await dataService.fetchUserData('user-123');
  await uiController.updateDisplay('Welcome back!');
  await uiController.navigateTo('HomeScreen');
  await dataService.syncData();
  await authService.refreshToken();
}

/// Example 17: Error tracking with full context
///
/// [20:55:54.758][f111296f][24752026][b2025.08.24][ErrorProneService][INFO][ErrorProneService.performRiskyOperation:596] Starting risky operation [package:any_logger/example/any_logger_example.dart(596:5)]
/// [20:55:54.758][f111296f][24752026][b2025.08.24][ErrorProneService][ERROR][ErrorProneService.performRiskyOperation:601] Risky operation failed [package:any_logger/example/any_logger_example.dart(601:7)]
/// 	Exception: Random processing failure
Future<void> errorTrackingExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        level: Level.DEBUG,
        format: '[%d][%did][%sid][%X{build}][%i][%l][%c] %m [%f]',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .withMdcValue('build', 'b2025.08.24')
      .build();
  final errorService = ErrorProneService();
  await errorService.performRiskyOperation();
  await errorService.handleNetworkRequest();
  await errorService.processUserInput('invalid@data');
}

/// Example 18: Performance monitoring with detailed logging
///
/// [20:55:54.761][f111296f][6e7c3349][staging][ANYLOGGER_SELF_LOGGER][INFO][LoggerFactory._setupSelfLogger:837] Setting level for all appenders to DEBUG [package:any_logger/src/logger_factory.dart(837:18)]
/// [20:55:54.761][f111296f][6e7c3349][staging][ANYLOGGER_SELF_LOGGER][DEBUG][LoggerFactory._setupSelfLogger:839] Self-debugging enabled [package:any_logger/src/logger_factory.dart(839:5)]
/// [20:55:54.761][f111296f][6e7c3349][staging][ANYLOGGER_SELF_LOGGER][DEBUG][LoggerFactory.initWithLoggerConfig:567] Logging system initialized with programmatic LoggerConfig with 1 active appenders [package:any_logger/src/logger_factory.dart(567:7)]
Future<void> performanceMonitoringExample() async {
  await LoggerFactory.dispose();
  await LoggerBuilder()
      .console(
        level: Level.DEBUG,
        format: '[%d][%did][%sid][%X{node}][%i][%l][%c] %m [%f]',
        dateFormat: 'HH:mm:ss.SSS',
      )
      .withMdcValue('node', 'node-03')
      .build();
  final perfMonitor = PerformanceMonitor();
  await perfMonitor.measureDatabaseQuery();
  await perfMonitor.measureApiCall();
  await perfMonitor.measureUIRendering();
  sleep(Duration(milliseconds: 100));
}

/// Example 16: Using AppenderBuilder for granular control
///
/// CONSOLE [INFO]: This info message goes to both console and file.
/// CONSOLE [ERROR]: This error also goes to both appenders.
/// CONSOLE [INFO]: And i am here because three lines look better...
Future<void> builderWithAppenderBuilderExample() async {
  await LoggerFactory.dispose();
  final fileAppender = await FileAppenderBuilder('granular_log')
      .withLevel(Level.TRACE)
      .withPath('logs/')
      .build();
  final consoleAppender = consoleAppenderBuilder()
      .withLevel(Level.INFO)
      .withFormat('CONSOLE [%i][%l]: %m')
      .buildSync();
  await LoggerBuilder()
      .withRootLevel(Level.TRACE)
      .addAppender(fileAppender)
      .addAppender(consoleAppender)
      .withSelfDebug()
      .build();
  Logger.info('This info message goes to both console and file.');
  Logger.error('This error also goes to both appenders.');
  Logger.info('And i am here because three lines look better...');
}

// ============================================================
// HELPER FUNCTIONS & CLASSES
// ============================================================
class UserService with AnyLogger {
  Future<void> createUser(String email) async {
    logInfo('Creating user: $email');
    await Future.delayed(Duration(milliseconds: 100));
    logInfo('User created successfully');
  }
}

class AuthService with AnyLogger {
  @override
  String get loggerName => 'AUTH';

  Future<bool> authenticate(String email, String password) async {
    logInfo('Authentication attempt for: $email');
    logDebug('Validating credentials');
    await Future.delayed(Duration(milliseconds: 200));
    logInfo('Authentication successful');
    return true;
  }
}

Future<void> handleUserRequest(String userId, String requestId) async {
  LoggerFactory.setMdcValue('userId', userId);
  LoggerFactory.setMdcValue('requestId', requestId);
  Logger.info('Request started');
  Logger.info('Request completed');
  LoggerFactory.removeMdcValue('userId');
  LoggerFactory.removeMdcValue('requestId');
}

class MyApplication with AnyLogger {
  @override
  String get loggerName => 'MyApplication';

  Future<void> initialize() async {
    logInfo('Initializing application');
    await Future.delayed(Duration(milliseconds: 50));
    logDebug('Loading configuration');
    logDebug('Setting up database connection');
    logInfo('Application initialized successfully');
  }

  Future<void> start() async {
    logInfo('Starting application');
    await Future.delayed(Duration(milliseconds: 30));
    logDebug('Starting background services');
    logInfo('Application started');
  }

  Future<void> handleUserAction(String action) async {
    logDebug('User action received: $action');
    await Future.delayed(Duration(milliseconds: 20));
    logInfo('Processed user action: $action');
  }

  Future<void> stop() async {
    logInfo('Stopping application');
    await Future.delayed(Duration(milliseconds: 30));
    logDebug('Stopping background services');
    logInfo('Application stopped');
  }

  Future<void> dispose() async {
    logInfo('Disposing application resources');
    await Future.delayed(Duration(milliseconds: 20));
    logDebug('Closing database connections');
    logInfo('Application disposed');
  }
}

class AuthenticationService with AnyLogger {
  @override
  String get loggerName => 'AuthService';

  Future<void> login(String email, String password) async {
    logInfo('Login attempt for user: $email');
    logDebug('Validating credentials');
    await Future.delayed(Duration(milliseconds: 100));
    logDebug('Credentials validated successfully');
    logInfo('User logged in: $email');
  }

  Future<void> refreshToken() async {
    logDebug('Refreshing authentication token');
    await Future.delayed(Duration(milliseconds: 50));
    logInfo('Token refreshed successfully');
  }
}

class DataService with AnyLogger {
  @override
  String get loggerName => 'DataService';

  Future<void> fetchUserData(String userId) async {
    logDebug('Fetching data for user: $userId');
    await Future.delayed(Duration(milliseconds: 80));
    logInfo('User data retrieved successfully');
  }

  Future<void> syncData() async {
    logInfo('Starting data synchronization');
    logDebug('Checking for local changes');
    await Future.delayed(Duration(milliseconds: 150));
    logInfo('Data synchronization completed');
  }
}

class UIController with AnyLogger {
  @override
  String get loggerName => 'UIController';

  Future<void> updateDisplay(String message) async {
    logDebug('Updating display with message: $message');
    await Future.delayed(Duration(milliseconds: 30));
    logInfo('Display updated');
  }

  Future<void> navigateTo(String screen) async {
    logInfo('Navigating to: $screen');
    await Future.delayed(Duration(milliseconds: 50));
    logInfo('Navigation completed: $screen');
  }
}

class ErrorProneService with AnyLogger {
  @override
  String get loggerName => 'ErrorProneService';

  Future<void> performRiskyOperation() async {
    logInfo('Starting risky operation');
    try {
      if (1 == 1) throw Exception('Random processing failure');
      logInfo('Risky operation completed successfully');
    } catch (e, stack) {
      logError('Risky operation failed', exception: e, stackTrace: stack);
    }
  }

  Future<void> handleNetworkRequest() async {
    try {
      if (1 == 1) throw SocketException('Connection timeout');
      logInfo('Network request successful');
    } catch (e) {
      logError('Network request failed', exception: e);
    }
  }

  Future<void> processUserInput(String input) async {
    if (!input.contains('@')) {
      logWarn('Invalid input format detected: $input');
    } else {
      logInfo('Valid input processed: $input');
    }
  }
}

class PerformanceMonitor with AnyLogger {
  @override
  String get loggerName => 'PerfMonitor';

  Future<void> measureDatabaseQuery() async {
    final stopwatch = Stopwatch()..start();
    await Future.delayed(Duration(milliseconds: Random().nextInt(100) + 50));
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed > 100) {
      logWarn('Slow database query: ${elapsed}ms');
    } else {
      logInfo('Database query completed: ${elapsed}ms');
    }
  }

  Future<void> measureApiCall() async {
    final stopwatch = Stopwatch()..start();
    await Future.delayed(Duration(milliseconds: Random().nextInt(200) + 100));
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed > 200) {
      logWarn('Slow API response: ${elapsed}ms');
    } else {
      logInfo('API call completed: ${elapsed}ms');
    }
  }

  Future<void> measureUIRendering() async {
    final stopwatch = Stopwatch()..start();
    await Future.delayed(Duration(milliseconds: Random().nextInt(50) + 10));
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed > 16) {
      logWarn('UI rendering exceeded frame budget: ${elapsed}ms');
    } else {
      logDebug('UI rendering within budget: ${elapsed}ms');
    }
  }
}

Future<void> cleanupExampleFiles() async {
  final logDir = Directory('logs');
  if (await logDir.exists()) {
    try {
      await for (final entity in logDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (e) {
      //
    }
  }
}

class MyCustomIdProvider implements IdProvider {
  // Don't use 'late' - initialize with null
  String? _deviceId;
  String? _sessionId;

  @override
  String? get deviceId => _deviceId;

  @override
  String? get sessionId => _sessionId;

  @override
  Future<void> initialize() async {
    // In a real implementation, you might load from secure storage
    _deviceId = 'my-device-id';
    _sessionId = 'my-session-id';
  }

  @override
  void initializeSync() {
    _deviceId = 'my-device-id';
    _sessionId = 'my-session-id';
  }

  @override
  void regenerateSessionId() {
    // Keep device ID, generate new session
    _deviceId ??= 'my-device-id';
    _sessionId = 'my-session-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void reset() {
    _deviceId = null;
    _sessionId = null;
  }

  @override
  void resetSession() {
    _sessionId = null;
  }

  @override
  // TODO: implement isInitialized
  bool get isInitialized => true;
}
