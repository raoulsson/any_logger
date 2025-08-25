import '../../any_logger.dart';

abstract class Appender {
  static const String defaultFormat = '%d %t %l %m %f';
  static const String defaultDateFormat = 'yyyy-MM-dd HH:mm:ss.SSS';
  late DateTime created;
  Level level = Level.INFO;
  int? clientDepthOffset;
  String format = defaultFormat;
  String dateFormat = defaultDateFormat;
  String? lineInfo;
  String initialFormat = defaultFormat;
  String initialDateFormat = defaultDateFormat;
  bool enabled = true;

  Appender({DateTime? customDate}) {
    created = customDate ?? DateTime.now();
  }

  String getType();

  void setEnabled(bool enabled) {
    this.enabled = enabled;
  }

  Future<void> dispose();

  Future<void> flush();

  void append(LogRecord logRecord);

  /// Creates a deep copy of this appender with all properties
  Appender createDeepCopy() {
    // This should be overridden by each concrete appender class
    throw UnimplementedError(
        'createDeepCopy must be implemented by concrete appender classes');
  }

  void copyBasePropertiesTo(Appender target) {
    target.level = level;
    target.format = format;
    target.initialFormat = initialFormat;
    target.dateFormat = dateFormat;
    target.initialDateFormat = initialDateFormat;
    target.clientDepthOffset = clientDepthOffset;
    target.created = created;
    target.lineInfo = lineInfo;
    target.enabled = enabled;
  }

  void initializeCommonProperties(Map<String, dynamic> config,
      {bool test = false, DateTime? date}) {
    created = date ?? DateTime.now();
    format = config['format'] ?? defaultFormat;
    initialFormat = format;
    dateFormat = config['dateFormat'] ?? defaultDateFormat;
    initialDateFormat = dateFormat;

    final levelStr = config['level'] as String?;
    if (levelStr != null) {
      level = Level.fromString(levelStr) ?? Level.INFO;
    }

    if (config.containsKey('depthOffset')) {
      clientDepthOffset = config['depthOffset'];
    }

    if (config.containsKey('enabled')) {
      enabled = config['enabled'];
    }
  }

  @override
  String toString() {
    return 'Appender(type: ${getType()}, level: $level, format: $format, dateFormat: $dateFormat, created: $created, enabled: $enabled)';
  }
}
