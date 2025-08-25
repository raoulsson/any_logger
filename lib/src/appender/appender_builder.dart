import '../../any_logger.dart';

/// A builder class for programmatically creating and configuring [Appender] instances.

class AppenderBuilder {
  final String _type;
  final Map<String, dynamic> _config = {};

  /// Creates a new builder for the specified [AppenderType].
  AppenderBuilder(this._type) {
    _config['type'] = _type.toUpperCase();
  }

  // --- Common Appender Properties ---

  /// Sets the logging [Level] for the appender.
  ///
  /// Only log records with a level equal to or higher than this will be processed.
  AppenderBuilder withLevel(Level level) {
    _config['level'] = level.name;
    return this;
  }

  /// Sets the log message format pattern.
  AppenderBuilder withFormat(String format) {
    _config['format'] = format;
    return this;
  }

  /// Sets the date format pattern to be used in the log message.
  AppenderBuilder withDateFormat(String dateFormat) {
    _config['dateFormat'] = dateFormat;
    return this;
  }

  /// Sets the initial enabled state of the appender.
  AppenderBuilder withEnabledState(bool enabled) {
    _config['enabled'] = enabled;
    return this;
  }

  /// Sets the client depth offset for call stack analysis.
  AppenderBuilder withDepthOffset(int offset) {
    _config['depthOffset'] = offset;
    return this;
  }

  /// Sets the [RotationCycle] for log file rotation.
  AppenderBuilder withRotationCycle(RotationCycle cycle) {
    if (_type != 'FILE') {
      throw StateError(
          'withRotationCycle is only applicable for FILE appender');
    }
    _config['rotationCycle'] = cycle.name;
    return this;
  }

  // --- Build Methods ---

  /// Builds the appender asynchronously using the specified configuration.
  ///
  /// This is the standard method and works for all appender types.
  /// Use the [test] flag to prevent actual I/O operations during unit tests.
  Future<Appender> build({bool test = false, DateTime? date}) async {
    // Add test and date to config if needed
    if (test) _config['test'] = test;
    if (date != null) _config['date'] = date;

    return AppenderRegistry.instance.create(_config);
  }

  /// Builds the appender synchronously (only for CONSOLE)
  Appender buildSync() {
    if (_type.toUpperCase() != 'CONSOLE') {
      throw UnsupportedError(
          'Synchronous building is only supported for CONSOLE appender. Use build() instead.');
    }
    return ConsoleAppender.fromConfigSync(_config);
  }
}
