// In: any_logger/lib/src/appender/appender_registry.dart

import '../../any_logger_lib.dart';

// A type definition for our factory functions
typedef AppenderFactoryFunction = Future<Appender> Function(Map<String, dynamic> config, {bool test, DateTime? date});

/// A central registry for creating Appender instances from configuration.
/// Extension packages can register their own appender types here.
class AppenderRegistry {
  // Private constructor for the singleton pattern
  AppenderRegistry._() {
    // Auto-register core appenders when the singleton is created
    _registerCoreAppenders();
  }

  // The single instance
  static final AppenderRegistry instance = AppenderRegistry._();

  // The map holding our "blueprints" for creating appenders
  final Map<String, AppenderFactoryFunction> _factories = {};

  // Track if core appenders are registered
  bool _coreAppendersRegistered = false;

  /// Registers the built-in appenders that are part of the core library.
  /// This is called automatically when the registry is first accessed.
  void _registerCoreAppenders() {
    if (_coreAppendersRegistered) return;

    // Register CONSOLE appender
    register('CONSOLE', (config, {test = false, date}) async {
      return ConsoleAppender.fromConfig(config, test: test, date: date);
    });

    // Register FILE appender
    register('FILE', (config, {test = false, date}) async {
      return FileAppender.fromConfig(config, test: test, date: date);
    });

    _coreAppendersRegistered = true;
  }

  /// Allows external packages to register a new appender type.
  void register(String type, AppenderFactoryFunction factory) {
    final upperType = type.toUpperCase();
    if (_factories.containsKey(upperType)) {
      // Log warning but allow overrides for testing
      if (Logger.getSelfLogger() != null) {
        Logger.getSelfLogger()?.logWarn('Overwriting appender factory for type $upperType');
      }
    }
    _factories[upperType] = factory;
  }

  /// Creates an appender instance from a config map based on its 'type'.
  /// The test and date parameters are passed separately, not in the config.
  Future<Appender> create(Map<String, dynamic> config, {bool test = false, DateTime? date}) async {
    // Ensure core appenders are registered
    if (!_coreAppendersRegistered) {
      _registerCoreAppenders();
    }

    final type = config['type']?.toString().toUpperCase();
    if (type == null) {
      throw ArgumentError("Appender configuration must contain a 'type' key.");
    }

    final factory = _factories[type];
    if (factory == null) {
      // Provide helpful error messages for common cases
      if (type == 'JSON_HTTP') {
        throw UnimplementedError("No appender registered for type '$type'. "
            "Please import the JSON_HTTP extension package:\n"
            "  import 'package:any_logger_json_http/any_logger_json_http.dart';");
      } else if (type == 'EMAIL') {
        throw UnimplementedError("No appender registered for type '$type'. "
            "Please import the EMAIL extension package:\n"
            "  import 'package:any_logger_email/any_logger_email.dart';");
      } else if (type == 'MYSQL') {
        throw UnimplementedError("No appender registered for type '$type'. "
            "Please import the MYSQL extension package:\n"
            "  import 'package:any_logger_mysql/any_logger_mysql.dart';");
      } else {
        throw UnimplementedError("No appender registered for type '$type'. "
            "Available types: ${_factories.keys.join(', ')}");
      }
    }

    // Pass test and date as named parameters, not in config
    return factory(config, test: test, date: date);
  }

  /// Unregisters an appender type (mainly for testing).
  void unregister(String type) {
    _factories.remove(type.toUpperCase());
  }

  /// Clears all registered appenders (mainly for testing).
  /// This will re-register core appenders on next access.
  void clear() {
    _factories.clear();
    _coreAppendersRegistered = false;
  }

  /// Gets a list of all registered appender types.
  List<String> getRegisteredTypes() {
    if (!_coreAppendersRegistered) {
      _registerCoreAppenders();
    }
    return _factories.keys.toList()..sort();
  }

  /// Checks if a specific appender type is registered.
  bool isRegistered(String type) {
    if (!_coreAppendersRegistered) {
      _registerCoreAppenders();
    }
    return _factories.containsKey(type.toUpperCase());
  }
}
