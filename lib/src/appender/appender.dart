import 'package:meta/meta.dart';

import '../../any_logger_lib.dart';

abstract class Appender {
  static const String defaultFormat = '%d %t %l %m %f';
  static const String defaultDateFormat = 'yyyy-MM-dd HH:mm:ss';
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

  Future<void> dispose();

  Future<void> flush();

  void append(LogRecord logRecord);

  /// Creates a deep copy of this appender with all properties
  Appender createDeepCopy() {
    // Create a new appender of the same type
    AppenderType appenderType = AppenderType.values
        .firstWhere((type) => type.name == getType());
    Appender copy = appenderType.createAppender();

    // Copy base properties
    copy.level = level;
    copy.format = format;
    copy.initialFormat = initialFormat;
    copy.dateFormat = dateFormat;
    copy.initialDateFormat = initialDateFormat;
    copy.clientDepthOffset = clientDepthOffset;
    copy.created = created;
    copy.lineInfo = lineInfo;
    copy.enabled = enabled;

    return copy;
  }

  @protected
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
    return 'Appender{type: ${getType()}, level: $level, format: $format, dateFormat: $dateFormat, enabled: $enabled}';
  }
}