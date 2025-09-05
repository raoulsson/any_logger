import '../../any_logger.dart';

/// A specialized builder for creating and configuring [FileAppender] instances.
///
/// This builder provides a fluent API specifically tailored for file appenders,
/// with file-specific configuration options like rotation, path, and file patterns.
///
/// ### Example Usage:
///
/// ```dart
/// // Simple file appender with daily rotation
/// final appender = await FileAppenderBuilder('app_log')
///     .withPath('logs/')
///     .withDailyRotation()
///     .build();
///
/// // Detailed file appender with custom settings
/// final customAppender = await FileAppenderBuilder('debug')
///     .withLevel(Level.DEBUG)
///     .withFormat('[%d][%l][%c] %m [%f]')
///     .withPath('logs/debug/')
///     .withFileExtension('txt')
///     .withMonthlyRotation()
///     .build();
///
/// // Using with LoggerBuilder
/// await LoggerBuilder()
///     .addAppender(await FileAppenderBuilder('app')
///         .withPath('logs/')
///         .withDailyRotation()
///         .build())
///     .build();
/// ```

/// Convenience factory function for creating a FileAppenderBuilder.
///
/// This allows for more concise code:
/// ```dart
/// final appender = await fileAppender('app_log')
///     .withPath('logs/')
///     .build();
/// ```
FileAppenderBuilder fileAppenderBuilder(String filePattern) =>
    FileAppenderBuilder(filePattern);

class FileAppenderBuilder {
  final Map<String, dynamic> _config = {
    'type': 'FILE',
  };

  /// Creates a new FileAppenderBuilder with the specified file pattern.
  ///
  /// The [filePattern] is the base name for log files. Depending on the
  /// rotation cycle, date suffixes will be added automatically.
  ///
  /// For example, with pattern 'app' and daily rotation:
  /// - `app_2024-03-15.log`
  /// - `app_2024-03-16.log`
  FileAppenderBuilder(String filePattern) {
    _config['filePattern'] = filePattern;
  }

  // --- Common Appender Properties ---

  /// Sets the logging [Level] for this file appender.
  ///
  /// Only log records with a level equal to or higher than this will be written.
  /// Defaults to [Level.DEBUG] for file appenders.
  FileAppenderBuilder withLevel(Level level) {
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
  /// Default: `'%d [%l][%t] %c - %m [%f]'`
  FileAppenderBuilder withFormat(String format) {
    _config['format'] = format;
    return this;
  }

  /// Sets the date format pattern for timestamps in log messages.
  ///
  /// Common patterns:
  /// - `'yyyy-MM-dd HH:mm:ss.SSS'` - Full timestamp (default for files)
  /// - `'HH:mm:ss.SSS'` - Time only
  /// - `'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''` - ISO 8601
  ///
  /// Default: `'yyyy-MM-dd HH:mm:ss.SSS'`
  FileAppenderBuilder withDateFormat(String dateFormat) {
    _config['dateFormat'] = dateFormat;
    return this;
  }

  /// Sets whether this appender starts in an enabled state.
  ///
  /// Default: `true`
  FileAppenderBuilder withEnabledState(bool enabled) {
    _config['enabled'] = enabled;
    return this;
  }

  /// Sets the stack trace depth offset for determining the calling location.
  ///
  /// Increase this value if you're wrapping the logger in additional layers.
  /// Default: `0`
  FileAppenderBuilder withDepthOffset(int offset) {
    _config['depthOffset'] = offset;
    return this;
  }

  // --- FileAppender Specific Properties ---

  /// Sets the directory path where log files will be stored.
  ///
  /// The path can be relative or absolute. Directories will be created
  /// if they don't exist.
  ///
  /// Examples:
  /// - `'logs/'` - Relative to app directory
  /// - `'/var/log/myapp/'` - Absolute path
  /// - `''` - Current directory (default)
  ///
  /// Default: `''` (current directory)
  FileAppenderBuilder withPath(String path) {
    _config['path'] = path;
    return this;
  }

  /// Sets the file extension for log files.
  ///
  /// Common extensions:
  /// - `'log'` - Standard log file (default)
  /// - `'txt'` - Plain text file
  /// - `'json'` - If using JSON formatting
  ///
  /// Default: `'log'`
  FileAppenderBuilder withFileExtension(String extension) {
    _config['fileExtension'] = extension;
    return this;
  }

  /// Sets the rotation cycle for log files.
  ///
  /// See also the convenience methods:
  /// - [withNoRotation]
  /// - [withDailyRotation]
  /// - [withWeeklyRotation]
  /// - [withMonthlyRotation]
  /// - [withYearlyRotation]
  FileAppenderBuilder withRotationCycle(RotationCycle cycle) {
    _config['rotationCycle'] = cycle.value;
    return this;
  }

  /// Sets the rotation cycle using a string value.
  ///
  /// Valid values: 'NEVER', 'DAY', 'WEEK', 'MONTH', 'YEAR'
  FileAppenderBuilder withRotationCycleString(String cycle) {
    _config['rotationCycle'] = cycle.toUpperCase();
    return this;
  }

  /// Sets whether to clear the log file contents on app startup.
  ///
  /// When enabled, the log file will be emptied every time the appender
  /// is initialized (typically on app startup). This is useful for
  /// applications that want fresh logs for each session.
  ///
  /// Default: `false`
  FileAppenderBuilder withClearOnStartup(bool clearOnStartup) {
    _config['clearOnStartup'] = clearOnStartup;
    return this;
  }

  // --- Rotation Convenience Methods ---

  /// Configures the appender to never rotate files.
  ///
  /// All logs will be written to a single file:
  /// `{filePattern}.{extension}`
  FileAppenderBuilder withNoRotation() {
    _config['rotationCycle'] = RotationCycle.NEVER.value; // 'never'
    return this;
  }

  /// Configures the appender to rotate files daily.
  ///
  /// Creates files like:
  /// `{filePattern}_2024-03-15.{extension}`
  FileAppenderBuilder withDailyRotation() {
    _config['rotationCycle'] = RotationCycle.DAILY.value; // 'day'
    return this;
  }

  /// Configures the appender to rotate files weekly.
  ///
  /// Creates files like:
  /// `{filePattern}_2024-CW11.{extension}`
  /// (CW = Calendar Week)
  FileAppenderBuilder withWeeklyRotation() {
    _config['rotationCycle'] = RotationCycle.WEEKLY.value; // 'week'
    return this;
  }

  /// Configures the appender to rotate files monthly.
  ///
  /// Creates files like:
  /// `{filePattern}_2024-03.{extension}`
  FileAppenderBuilder withMonthlyRotation() {
    _config['rotationCycle'] = RotationCycle.MONTHLY.value; // 'month'
    return this;
  }

  // --- Preset Configurations ---

  /// Applies a simple preset suitable for basic file logging.
  ///
  /// - Format: `'%d [%l] %m'`
  /// - Level: INFO
  /// - Rotation: Daily
  FileAppenderBuilder withSimplePreset() {
    _config['format'] = '%d [%l] %m';
    _config['level'] = Level.INFO.name;
    _config['rotationCycle'] = RotationCycle.DAILY.value; // 'day'
    return this;
  }

  /// Applies a detailed preset suitable for debugging.
  ///
  /// - Format: `'[%d][%l][%c] %m [%f]'`
  /// - Level: DEBUG
  /// - Rotation: Daily
  FileAppenderBuilder withDebugPreset() {
    _config['format'] = '[%d][%l][%c] %m [%f]';
    _config['level'] = Level.DEBUG.name;
    _config['rotationCycle'] = RotationCycle.DAILY.value; // 'day'
    return this;
  }

  /// Applies a production preset with essential information.
  ///
  /// - Format: `'[%d][%l][%t] %m'`
  /// - Level: INFO
  /// - Rotation: Weekly
  FileAppenderBuilder withProductionPreset() {
    _config['format'] = '[%d][%l][%t] %m';
    _config['level'] = Level.INFO.name;
    _config['rotationCycle'] = RotationCycle.WEEKLY.value; // 'week'
    return this;
  }

  /// Applies a preset with full tracking information.
  ///
  /// - Format: `'[%d][%did][%sid][%i][%l][%c] %m [%f]'`
  /// - Level: TRACE
  /// - Rotation: Daily
  FileAppenderBuilder withFullTrackingPreset() {
    _config['format'] = '[%d][%did][%sid][%i][%l][%c] %m [%f]';
    _config['level'] = Level.TRACE.name;
    _config['rotationCycle'] = RotationCycle.DAILY.value; // 'day'
    return this;
  }

  /// Applies an audit preset for compliance logging.
  ///
  /// - Format: `'[AUDIT][%d][%did][%sid][%X{userId}][%l] %m [%f]'`
  /// - Level: INFO
  /// - Rotation: Monthly (for longer retention)
  FileAppenderBuilder withAuditPreset() {
    _config['format'] = '[AUDIT][%d][%did][%sid][%X{userId}][%l] %m [%f]';
    _config['level'] = Level.INFO.name;
    _config['rotationCycle'] = RotationCycle.MONTHLY.value; // 'month'
    return this;
  }

  // --- Build Methods ---

  /// Builds the file appender asynchronously.
  ///
  /// This method creates the necessary directories and files if they don't exist.
  ///
  /// The [test] parameter can be used to prevent actual file I/O during testing.
  /// The [date] parameter can be used to override the creation date for testing.
  ///
  /// Returns a Future that resolves to a fully configured [FileAppender] instance.
  Future<FileAppender> build({bool test = false, DateTime? date}) async {
    // Set defaults if not specified
    _config['dateFormat'] ??= 'yyyy-MM-dd HH:mm:ss.SSS';
    _config['fileExtension'] ??= 'log';
    _config['rotationCycle'] ??= RotationCycle.DAILY.value;
    _config['path'] ??= '';

    return FileAppender.fromConfig(_config, test: test, date: date);
  }

  /// Creates a copy of this builder with the same configuration.
  ///
  /// Useful for creating multiple similar appenders with slight variations.
  FileAppenderBuilder copy() {
    final filePattern = _config['filePattern'] as String;
    final newBuilder = FileAppenderBuilder(filePattern);
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

  /// Gets the full file path that will be used for the log file.
  ///
  /// This is useful for debugging or displaying to users where logs will be saved.
  /// Note: The actual filename will include date suffixes based on rotation settings.
  String getExpectedFilePath() {
    final path = _config['path'] ?? '';
    final pattern = _config['filePattern'] ?? 'log';
    final extension = _config['fileExtension'] ?? 'log';
    final rotation = _config['rotationCycle'] ?? 'DAY';

    String fullPath = path;
    if (fullPath.isNotEmpty && !fullPath.endsWith('/')) {
      fullPath += '/';
    }

    switch (rotation.toUpperCase()) {
      case 'NEVER':
        return '$fullPath$pattern.$extension';
      case 'DAY':
        return '$fullPath${pattern}_YYYY-MM-DD.$extension';
      case 'WEEK':
        return '$fullPath${pattern}_YYYY-CWxx.$extension';
      case 'MONTH':
        return '$fullPath${pattern}_YYYY-MM.$extension';
      case 'YEAR':
        return '$fullPath${pattern}_YYYY.$extension';
      default:
        return '$fullPath$pattern.$extension';
    }
  }

  @override
  String toString() {
    return 'FileAppenderBuilder(config: $_config)';
  }
}
