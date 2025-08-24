import '../../any_logger.dart';

/// A specialized builder for creating and configuring [ConsoleAppender] instances.
///
/// This builder provides a fluent API specifically tailored for console appenders,
/// with only the relevant configuration options exposed.
///
/// ### Example Usage:
///
/// ```dart
/// // Simple console appender with default settings
/// final appender = ConsoleAppenderBuilder().buildSync();
///
/// // Customized console appender
/// final customAppender = ConsoleAppenderBuilder()
///     .withLevel(Level.DEBUG)
///     .withFormat('[%d] [%l] %m')
///     .withDateFormat('HH:mm:ss.SSS')
///     .withMode(ConsoleLoggerMode.devtools)
///     .buildSync();
///
/// // Using with LoggerBuilder
/// await LoggerBuilder()
///     .addAppender(ConsoleAppenderBuilder()
///         .withLevel(Level.INFO)
///         .withFormat('[%l] %m')
///         .buildSync())
///     .build();
/// ```

/// Convenience factory function for creating a ConsoleAppenderBuilder.
///
/// This allows for more concise code:
/// ```dart
/// final appender = consoleAppender()
///     .withLevel(Level.DEBUG)
///     .buildSync();
/// ```
ConsoleAppenderBuilder consoleAppenderBuilder() => ConsoleAppenderBuilder();

class ConsoleAppenderBuilder {
  final Map<String, dynamic> _config = {
    'type': 'CONSOLE',
  };

  /// Creates a new ConsoleAppenderBuilder with default settings.
  ConsoleAppenderBuilder();

  // --- Common Appender Properties ---

  /// Sets the logging [Level] for this console appender.
  ///
  /// Only log records with a level equal to or higher than this will be displayed.
  /// Defaults to [Level.INFO].
  ConsoleAppenderBuilder withLevel(Level level) {
    _config['level'] = level.name;
    return this;
  }

  /// Sets the log message format pattern.
  ///
  /// Format placeholders:
  /// - `%d` - Timestamp
  /// - `%l` - Log level
  /// - `%m` - Message
  /// - `%c` - Class.method:line
  /// - `%f` - File location
  /// - `%t` - Tag
  /// - `%i` - Logger name
  /// - `%did` - Device ID
  /// - `%sid` - Session ID
  /// - `%app` - App version
  /// - `%X{key}` - MDC value
  ///
  /// Default: `'%d %t %l %m %f'`
  ConsoleAppenderBuilder withFormat(String format) {
    _config['format'] = format;
    return this;
  }

  /// Sets the date format pattern for timestamps in log messages.
  ///
  /// Common patterns:
  /// - `'HH:mm:ss.SSS'` - Time with milliseconds (default for console)
  /// - `'yyyy-MM-dd HH:mm:ss'` - Full date and time
  /// - `'HH:mm:ss'` - Simple time
  ///
  /// Default: `'yyyy-MM-dd HH:mm:ss.SSS'`
  ConsoleAppenderBuilder withDateFormat(String dateFormat) {
    _config['dateFormat'] = dateFormat;
    return this;
  }

  /// Sets whether this appender starts in an enabled state.
  ///
  /// Default: `true`
  ConsoleAppenderBuilder withEnabledState(bool enabled) {
    _config['enabled'] = enabled;
    return this;
  }

  /// Sets the stack trace depth offset for determining the calling location.
  ///
  /// Increase this value if you're wrapping the logger in additional layers.
  /// Default: `0`
  ConsoleAppenderBuilder withDepthOffset(int offset) {
    _config['depthOffset'] = offset;
    return this;
  }

  // --- ConsoleAppender Specific Properties ---

  /// Sets the output mode for the console appender.
  ///
  /// - [ConsoleLoggerMode.stdout] - Uses `print()` for output (default)
  /// - [ConsoleLoggerMode.devtools] - Uses `dart:developer` log function
  ///
  /// The devtools mode provides better integration with Flutter DevTools
  /// and IDE debugging consoles.
  ConsoleAppenderBuilder withMode(ConsoleLoggerMode mode) {
    _config['mode'] = mode == ConsoleLoggerMode.stdout ? 'stdout' : 'devtools';
    return this;
  }

  /// Sets the appender to use stdout mode (print statements).
  ///
  /// This is the default mode.
  ConsoleAppenderBuilder withStdoutMode() {
    _config['mode'] = 'stdout';
    return this;
  }

  /// Sets the appender to use devtools mode.
  ///
  /// This mode uses `dart:developer`'s log function for better
  /// integration with debugging tools.
  ConsoleAppenderBuilder withDevtoolsMode() {
    _config['mode'] = 'devtools';
    return this;
  }

  // --- Preset Configurations ---

  /// Applies a simple preset suitable for basic console logging.
  ///
  /// Format: `'%d [%l] %m'`
  /// Date format: `'HH:mm:ss.SSS'`
  ConsoleAppenderBuilder withSimplePreset() {
    _config['format'] = '%d [%l] %m';
    _config['dateFormat'] = 'HH:mm:ss.SSS';
    _config['level'] = Level.INFO.name;
    return this;
  }

  /// Applies a detailed preset suitable for development/debugging.
  ///
  /// Format: `'[%d][%l][%c] %m [%f]'`
  /// Date format: `'HH:mm:ss.SSS'`
  /// Level: DEBUG
  ConsoleAppenderBuilder withDebugPreset() {
    _config['format'] = '[%d][%l][%c] %m [%f]';
    _config['dateFormat'] = 'HH:mm:ss.SSS';
    _config['level'] = Level.DEBUG.name;
    return this;
  }

  /// Applies a minimal preset for production use.
  ///
  /// Format: `'%l: %m'`
  /// Level: WARN
  ConsoleAppenderBuilder withProductionPreset() {
    _config['format'] = '%l: %m';
    _config['level'] = Level.WARN.name;
    return this;
  }

  /// Applies a preset with full tracking information.
  ///
  /// Format: `'[%d][%did][%sid][%i][%l][%c] %m [%f]'`
  /// Date format: `'HH:mm:ss.SSS'`
  /// Level: TRACE
  ConsoleAppenderBuilder withFullTrackingPreset() {
    _config['format'] = '[%d][%did][%sid][%i][%l][%c] %m [%f]';
    _config['dateFormat'] = 'HH:mm:ss.SSS';
    _config['level'] = Level.TRACE.name;
    return this;
  }

  // --- Build Methods ---

  /// Builds the console appender synchronously.
  ///
  /// This is the preferred method for console appenders as they don't
  /// require any async initialization.
  ///
  /// Returns a fully configured [ConsoleAppender] instance.
  ConsoleAppender buildSync() {
    return ConsoleAppender.fromConfigSync(_config);
  }

  /// Builds the console appender asynchronously.
  ///
  /// This method is provided for API consistency with other appender builders,
  /// but [buildSync] is preferred for console appenders.
  ///
  /// Returns a Future that resolves to a fully configured [ConsoleAppender] instance.
  Future<ConsoleAppender> build({bool test = false, DateTime? date}) async {
    return ConsoleAppender.fromConfig(_config, test: test, date: date);
  }

  /// Creates a copy of this builder with the same configuration.
  ///
  /// Useful for creating multiple similar appenders with slight variations.
  ConsoleAppenderBuilder copy() {
    final newBuilder = ConsoleAppenderBuilder();
    newBuilder._config.addAll(_config);
    return newBuilder;
  }

  /// Gets the current configuration as a Map.
  ///
  /// This is mainly useful for debugging or for passing the configuration
  /// to other parts of the system.
  Map<String, dynamic> getConfig() {
    return Map.unmodifiable(_config);
  }

  @override
  String toString() {
    return 'ConsoleAppenderBuilder(config: $_config)';
  }
}
