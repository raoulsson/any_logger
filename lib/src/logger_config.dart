// ============================================================
// LoggerConfig Class
// ============================================================

import '../any_logger_lib.dart';

/// A configuration class to hold a list of appenders and a root logging level.
///
/// This is used for programmatic configuration where appenders are built
/// manually (e.g., using [AppenderBuilder]) and then passed to the
/// [LoggerFactory] for initialization.
class LoggerConfig {
  /// The list of appenders to be used for logging.
  final List<Appender> appenders;

  /// The root logging level. Only messages with this level or higher will be
  /// considered by the logger, before being passed to the appenders.
  final Level level;

  /// Creates a new logger configuration.
  ///
  /// [appenders]: A list of configured [Appender] instances.
  /// [level]: The minimum level for the root logger. Defaults to [Level.INFO].
  LoggerConfig({
    required this.appenders,
    this.level = Level.INFO,
  });
}
