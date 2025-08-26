/// A powerful, flexible, and intuitive logging library for Dart and Flutter applications.
///
/// This library provides a comprehensive logging solution with:
/// - Zero configuration quick start
/// - Progressive complexity from simple to enterprise
/// - Automatic device/session tracking
/// - Multiple appender types (console, file, and extensible)
/// - Performance optimizations with early exits and lazy evaluation
///
/// ## Quick Start
///
/// ```dart
/// import 'package:any_logger/any_logger.dart';
///
/// void main() {
///   Logger.info("I'm logging!"); // Auto-configures on first use
/// }
/// ```
///
/// ## Using the Mixin
///
/// ```dart
/// class MyService with AnyLogger {
///   @override
///   String get loggerName => 'MyService';
///
///   void doWork() {
///     logInfo('Starting work');
///     logDebug('Debug details');
///   }
/// }
/// ```
library any_logger;

// Core Components
// ---------------

/// Mixin that provides logging capabilities to any class.
/// Use this to add logging methods to your classes with automatic
/// caching and performance optimizations.
export 'src/any_logger.dart';

/// The singleton factory for managing loggers and appenders.
/// This is the main entry point for configuring the logging system.
export 'src/logger_factory.dart';

/// The Logger class that performs the actual logging.
/// Usually obtained via LoggerFactory.getLogger() or the AnyLogger mixin.
export 'src/logger.dart';

/// A single log entry containing message, level, timestamp, and context.
export 'src/log_record.dart';

/// Logging severity levels from TRACE to FATAL.
export 'src/level.dart';

// Appenders (Output Destinations)
// --------------------------------

/// Base class for all appenders. Extend this to create custom appenders.
export 'src/appender/appender.dart';

/// Console appender that outputs colored logs to stdout/stderr.
export 'src/appender/console_appender.dart';

/// File appender with rotation support for persistent logging.
export 'src/appender/file_appender.dart';

/// Registry for managing appender types and enabling extensions.
export 'src/appender/appender_registry.dart';

// Builder Pattern APIs
// --------------------

/// Fluent builder for configuring loggers with multiple appenders.
export 'src/logger_builder.dart';

/// Base builder class for appender configuration.
export 'src/appender/appender_builder.dart';

/// Builder for configuring console appenders.
export 'src/appender/console_appender_builder.dart';

/// Builder for configuring file appenders with rotation.
export 'src/appender/file_appender_builder.dart';

// Configuration
// -------------

/// Configuration model for logger initialization.
export 'src/logger_config.dart';

/// Pre-configured logger setups for common use cases (development, production, etc).
export 'src/logger_presets.dart';

/// File rotation strategies (HOUR, DAY, WEEK, MONTH, SIZE).
export 'src/appender/rotation_cycle.dart';

// ID Providers (Device/Session Tracking)
// ---------------------------------------

/// Base interface for ID providers.
export 'src/id_provider/id_provider.dart';

/// File-based ID provider for persistent device IDs (default on Dart).
export 'src/id_provider/file_id_provider.dart';

/// Memory-based ID provider for non-persistent IDs.
export 'src/id_provider/mem_id_provider.dart';

/// No-op ID provider when tracking is not needed.
export 'src/id_provider/null_id_provider.dart';

/// Automatic resolver that selects the best ID provider for the platform.
export 'src/id_provider/id_provider_resolver.dart';

/// Utility for generating unique IDs.
export 'src/id_provider/id_generator.dart';

// Utilities
// ---------

/// Formatter that converts log records to strings using patterns.
export 'src/log_record_formatter.dart';

/// Stack trace parser for extracting file locations and line numbers.
export 'src/logger_stack_trace.dart';

/// Date formatting utilities for log timestamps.
export 'src/simple_date_format.dart';

/// General utility functions.
export 'src/utils.dart';

/// Internal constants used by the library.
export 'src/constants.dart';
