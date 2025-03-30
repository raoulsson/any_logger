import 'package:meta/meta.dart';

import '../../any_logger_lib.dart';

abstract class Appender {
  static const String defaultFormat = '%d %t %l %m %f';

  static const String defaultDateFormat = 'yyyy-MM-dd HH:mm:ss';

  bool brackets = false;

  late DateTime created;

  Level level = Level.INFO;

  int? clientDepthOffset;

  String? lineInfo;

  String format = defaultFormat;

  String dateFormat = defaultDateFormat;

  Appender({DateTime? customDate}) {
    created = customDate ?? DateTime.now();
  }

  AppenderType getType();

  void append(LogRecord logRecord);

  @protected
  void initializeCommonProperties(Map<String, dynamic> config,
      {bool test = false, DateTime? date}) {
    created = date ?? DateTime.now();
    format = config['format'] ?? defaultFormat;
    dateFormat = config['dateFormat'] ?? defaultDateFormat;
    brackets = config['brackets'] ?? false;

    final levelStr = config['level'] as String?;
    if (levelStr != null) {
      level = Level.fromString(levelStr) ?? Level.INFO;
    }

    if (config.containsKey('depthOffset')) {
      clientDepthOffset = config['depthOffset'];
    }
  }
}
