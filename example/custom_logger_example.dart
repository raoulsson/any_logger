import 'dart:io';

import 'package:any_logger/any_logger.dart';

/// Example demonstrating how to create custom loggers with specific appenders
/// that can be retrieved later by name from anywhere in your application.
///
/// This solves the use case where you need specialized loggers (e.g., AI logs,
/// audit logs, feature-specific logs) that write to separate files or have
/// different configurations from your main application logging.
void main() async {
  print('╔══════════════════════════════════════════════════╗');
  print('║  Custom Logger Registration Examples             ║');
  print('╚══════════════════════════════════════════════════╝');

  // Clean up any existing test files
  await cleanupExampleFiles();

  try {
    // Initialize main application logging
    await initializeMainLogging();

    // Example 1: Auto-registration with Logger.defaultLogger (Option 2)
    await exampleAutoRegistration();

    // Example 2: Factory method LoggerFactory.createCustomLogger (Option 3)
    await exampleFactoryMethod();

    // Example 3: Real-world AI logging scenario
    await exampleAiLogging();

    // Example 4: Multiple specialized loggers
    await exampleMultipleSpecializedLoggers();
  } finally {
    // Clean up
    await LoggerFactory.flushAll();
    await LoggerFactory.dispose();
  }
}

/// Initialize main application logging
Future<void> initializeMainLogging() async {
  print('\n📋 Initializing main application logging...');

  await LoggerFactory.initFile(
    filePattern: 'main_app',
    fileLevel: Level.DEBUG,
    consoleLevel: Level.INFO,
  );

  // Test main logging
  final mainLogger = LoggerFactory.getRootLogger();
  mainLogger.logInfo('Main application logging initialized');

  print('✅ Main logging ready');
}

/// Example 1: Auto-registration with Logger.defaultLogger
/// This demonstrates the enhanced Logger.defaultLogger that now auto-registers named loggers
Future<void> exampleAutoRegistration() async {
  print('\n╔══════════════════════════════════════════════════╗');
  print('║  Option 2: Auto-Registration Example            ║');
  print('╚══════════════════════════════════════════════════╝');

  print('Creating custom appender for audit logging...');

  // Create a dedicated file appender for audit logs
  final auditAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d][AUDIT] %m',
    'level': 'INFO',
    'dateFormat': 'yyyy-MM-dd HH:mm:ss.SSS',
    'filePattern': 'audit_log',
    'path': 'logs/',
    'clearOnStartup': true,
  });

  print('Creating logger with Logger.defaultLogger (auto-registration)...');

  // OLD WAY (that didn't work): Logger would be created but not retrievable
  // NEW WAY: Logger.defaultLogger now auto-registers named loggers!
  final auditLogger = Logger.defaultLogger([auditAppender], name: 'AUDIT-LOGGER');

  // Test immediate usage
  auditLogger.logInfo('USER_LOGIN user=john.doe session=abc123');
  auditLogger.logInfo('PERMISSION_GRANTED user=john.doe resource=reports');

  print('Testing retrieval from anywhere else in the application...');

  // This now works! Previously this would create a different logger
  final retrievedAuditLogger = LoggerFactory.getLogger('AUDIT-LOGGER');
  retrievedAuditLogger.logInfo('AUDIT_TRAIL_ACCESS user=admin action=view_logs');

  // Verify they are the same instance
  print('✅ Same logger instance: ${identical(auditLogger, retrievedAuditLogger)}');
  print('✅ Logger name: ${retrievedAuditLogger.name}');
  print('✅ Appender count: ${retrievedAuditLogger.appenders.length}');
}

/// Example 2: Factory method LoggerFactory.createCustomLogger
/// This is the recommended clean API for this use case
Future<void> exampleFactoryMethod() async {
  print('\n╔══════════════════════════════════════════════════╗');
  print('║  Option 3: Factory Method Example (Recommended) ║');
  print('╚══════════════════════════════════════════════════╝');

  print('Creating custom logger via LoggerFactory.createCustomLogger...');

  // Create appender for debug traces
  final debugAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d][DEBUG][%c] %m [%f]',
    'level': 'TRACE',
    'dateFormat': 'HH:mm:ss.SSS',
    'filePattern': 'debug_trace',
    'path': 'logs/',
    'clearOnStartup': true,
  });

  // RECOMMENDED WAY: Use the new factory method
  final debugLogger = LoggerFactory.createCustomLogger('DEBUG-TRACER', [debugAppender]);

  // Test immediate usage
  debugLogger.logTrace('Function entry: calculatePayment()');
  debugLogger.logDebug('Processing payment amount: \$129.99');
  debugLogger.logTrace('Function exit: calculatePayment() -> success');

  print('Testing retrieval from anywhere else...');

  // Retrieve from anywhere in your application
  final retrievedDebugLogger = LoggerFactory.getLogger('DEBUG-TRACER');
  retrievedDebugLogger.logDebug('Database query took 45ms');
  retrievedDebugLogger.logTrace('Cache hit for key: user_preferences_123');

  // Verify same instance
  print('✅ Same logger instance: ${identical(debugLogger, retrievedDebugLogger)}');
  print('✅ Trace level enabled: ${retrievedDebugLogger.isTraceEnabled}');
}

/// Example 3: Real-world AI logging scenario (matches your use case)
Future<void> exampleAiLogging() async {
  print('\n╔══════════════════════════════════════════════════╗');
  print('║  Real-World Example: AI Quality Assessment Logs ║');
  print('╚══════════════════════════════════════════════════╝');

  print('Setting up AI quality assessment logger (like your use case)...');

  // Create AI-specific appender (similar to your setup)
  final aiAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d] %m', // Simple format like in your code
    'level': 'DEBUG',
    'dateFormat': 'HH:mm:ss.SSS',
    'filePattern': 'ai_quality_log',
    'clearOnStartup': true, // Fresh logs on startup like in your code
  });

  // Method 1: Your original approach (now works!)
  print('Creating AI logger with Logger.defaultLogger...');
  final aiLogger = Logger.defaultLogger([aiAppender], name: 'AI-LOGGER');

  // Simulate AI processing
  aiLogger.logInfo('AI quality assessment started');
  aiLogger.logDebug('Model: GPT-4, Temperature: 0.7');
  aiLogger.logInfo('Processing prompt: "Analyze this code for bugs"');
  aiLogger.logDebug('Response tokens: 1247, Processing time: 2.3s');
  aiLogger.logInfo('Quality score: 8.5/10');

  print('Retrieving AI logger from elsewhere in your application...');

  // Simulate retrieving from your client code (this now works!)
  final clientAiLogger = LoggerFactory.getLogger('AI-LOGGER');
  clientAiLogger.logInfo('Client side: Starting AI batch processing');
  clientAiLogger.logDebug('Batch size: 50 requests');
  clientAiLogger.logInfo('Client side: Batch processing complete');

  print('✅ Your use case now works! aiLogger == clientAiLogger: ${identical(aiLogger, clientAiLogger)}');
}

/// Example 4: Multiple specialized loggers working together
Future<void> exampleMultipleSpecializedLoggers() async {
  print('\n╔══════════════════════════════════════════════════╗');
  print('║  Multiple Specialized Loggers Example           ║');
  print('╚══════════════════════════════════════════════════╝');

  print('Creating multiple specialized loggers for different purposes...');

  // Security logger
  final securityAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d][SECURITY] %m',
    'level': 'WARN',
    'filePattern': 'security',
    'path': 'logs/',
    'clearOnStartup': true,
  });

  // Performance logger
  final perfAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d][PERF] %m',
    'level': 'INFO',
    'filePattern': 'performance',
    'path': 'logs/',
    'clearOnStartup': true,
  });

  // Business logic logger
  final businessAppender = await FileAppender.fromConfig({
    'type': 'FILE',
    'format': '[%d][BUSINESS] %m',
    'level': 'DEBUG',
    'filePattern': 'business_logic',
    'path': 'logs/',
    'clearOnStartup': true,
  });

  // Create multiple loggers using different approaches
  final securityLogger = LoggerFactory.createCustomLogger('SECURITY', [securityAppender]);
  final perfLogger = Logger.defaultLogger([perfAppender], name: 'PERFORMANCE');
  final businessLogger = LoggerFactory.createCustomLogger('BUSINESS-LOGIC', [businessAppender]);

  // Test all loggers
  securityLogger.logWarn('Failed login attempt from IP: 192.168.1.100');
  perfLogger.logInfo('API endpoint /users took 234ms');
  businessLogger.logDebug('User upgraded to premium plan: user_456');

  print('Retrieving all loggers from different parts of application...');

  // Simulate retrieval from different modules
  final retrievedSecurity = LoggerFactory.getLogger('SECURITY');
  final retrievedPerf = LoggerFactory.getLogger('PERFORMANCE');
  final retrievedBusiness = LoggerFactory.getLogger('BUSINESS-LOGIC');

  // Test retrieved loggers
  retrievedSecurity.logError('CRITICAL: Potential SQL injection detected');
  retrievedPerf.logInfo('Database connection pool: 45/50 connections active');
  retrievedBusiness.logInfo('Monthly report generated for 1,250 users');

  // Verify they are the same instances
  print('✅ Security logger same instance: ${identical(securityLogger, retrievedSecurity)}');
  print('✅ Performance logger same instance: ${identical(perfLogger, retrievedPerf)}');
  print('✅ Business logger same instance: ${identical(businessLogger, retrievedBusiness)}');

  print('\n📊 Summary: All specialized loggers working independently!');
  print('   - Security logs: logs/security_*.log');
  print('   - Performance logs: logs/performance_*.log');
  print('   - Business logs: logs/business_logic_*.log');
  print('   - Main app logs: main_app_*.log');
}

/// Clean up any example files from previous runs
Future<void> cleanupExampleFiles() async {
  try {
    final logsDir = Directory('logs');
    if (await logsDir.exists()) {
      await logsDir.delete(recursive: true);
    }

    // Clean up any log files in current directory
    final currentDir = Directory.current;
    await for (final file in currentDir.list()) {
      if (file is File && file.path.endsWith('.log')) {
        await file.delete();
      }
    }
  } catch (e) {
    // Ignore cleanup errors
  }
}
