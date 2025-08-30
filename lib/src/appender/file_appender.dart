import 'dart:io';

import '../../any_logger.dart';

class FileAppender extends Appender {
  String? filePattern;
  String fileExtension = 'log';
  String path = 'logs/';
  RotationCycle rotationCycle = RotationCycle.NEVER;
  late File _file;
  String? _resolvedBasePath; // Store the resolved base path for this instance

  // Flutter apps MUST set this for file operations
  static Future<Directory> Function()? getAppDocumentsDirectoryFnc;

  FileAppender() : super();

  static Future<FileAppender> fromConfig(Map<String, dynamic> config, {bool test = false, DateTime? date}) async {
    final appender = FileAppender()..created = date ?? DateTime.now();

    appender.initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('filePattern')) {
      appender.filePattern = config['filePattern'];
    } else {
      throw ArgumentError('Missing file argument for file appender');
    }

    if (config.containsKey('fileExtension')) {
      appender.fileExtension = config['fileExtension'];
    }

    if (config.containsKey('rotationCycle')) {
      appender.rotationCycle = Utils.getRotationCycleFromString(config['rotationCycle']);
    }

    if (config.containsKey('path')) {
      appender.path = config['path'];
    }

    // Resolve the base path once during initialization
    if (getAppDocumentsDirectoryFnc != null) {
      final dir = await getAppDocumentsDirectoryFnc!();
      appender._resolvedBasePath = dir.path;
    }

    appender._ensurePathExists();

    return appender;
  }

  /// Ensures the directory and file exist
  void _ensurePathExists() {
    final fullPath = _getFullFilename();
    final file = File(fullPath);

    final directory = file.parent;
    if (!directory.existsSync()) {
      try {
        directory.createSync(recursive: true);
        Logger.getSelfLogger()?.logTrace('Created directory: ${directory.path}');
      } catch (e) {
        Logger.getSelfLogger()?.logError('Failed to create directory: ${directory.path}: $e');
        throw Exception('Cannot create log directory: ${directory.path}');
      }
    }

    if (!file.existsSync()) {
      try {
        file.createSync();
        Logger.getSelfLogger()?.logTrace('Created log file: $fullPath');
      } catch (e) {
        Logger.getSelfLogger()?.logError('Failed to create log file: $fullPath: $e');
        throw Exception('Cannot create log file: $fullPath');
      }
    }

    _file = file;
  }

  @override
  Appender createDeepCopy() {
    FileAppender copy = FileAppender();
    copyBasePropertiesTo(copy);
    copy.filePattern = filePattern;
    copy.fileExtension = fileExtension;
    copy.path = path;
    copy.rotationCycle = rotationCycle;
    copy._resolvedBasePath = _resolvedBasePath; // Copy the resolved path
    copy._ensurePathExists();
    return copy;
  }

  String _getFullFilename() {
    String fullPath;

    // If we have a resolved base path, we're in Flutter mode
    if (_resolvedBasePath != null) {
      // Flutter mode - everything goes under app documents
      String cleanPath = path;
      // Remove leading slash
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      // Replace Windows drive letters (C:/ becomes C_/)
      if (cleanPath.length > 1 && cleanPath[1] == ':') {
        cleanPath = cleanPath.replaceFirst(':', '_');
      }

      fullPath = '$_resolvedBasePath/$cleanPath';
    } else {
      // Standard filesystem mode - use path as given (absolute or relative)
      fullPath = path;
    }

    // Ensure path ends with separator
    if (fullPath.isNotEmpty && !fullPath.endsWith('/') && !fullPath.endsWith('\\')) {
      fullPath += '/';
    }

    switch (rotationCycle) {
      case RotationCycle.NEVER:
        return '$fullPath${filePattern!}.$fileExtension';
      case RotationCycle.DAY:
        return '$fullPath${filePattern!}_${SimpleDateFormat('yyyy-MM-dd').format(created)}.$fileExtension';
      case RotationCycle.WEEK:
        return '$fullPath${filePattern!}_${created.year}-CW${Utils.getCalendarWeek(created)}.$fileExtension';
      case RotationCycle.MONTH:
        return '$fullPath${filePattern!}_${SimpleDateFormat('yyyy-MM').format(created)}.$fileExtension';
      case RotationCycle.YEAR:
        return '$fullPath${filePattern!}_${SimpleDateFormat('yyyy').format(created)}.$fileExtension';
    }
  }

  @override
  void append(LogRecord logRecord) async {
    if (!enabled) return;

    switch (rotationCycle) {
      case RotationCycle.NEVER:
        break;
      case RotationCycle.DAY:
      case RotationCycle.WEEK:
      case RotationCycle.MONTH:
      case RotationCycle.YEAR:
        await checkForFileChange();
        break;
    }

    logRecord.loggerName ??= getType().toString();

    try {
      _file.writeAsStringSync('${LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat)}\n',
          mode: FileMode.append);

      if (logRecord.stackTrace != null) {
        _file.writeAsStringSync('${logRecord.stackTrace}\n', mode: FileMode.append);
      }
    } catch (e) {
      Logger.getSelfLogger()?.logError('Failed to write to log file: $e');
      try {
        _ensurePathExists();
        _file.writeAsStringSync('${LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat)}\n',
            mode: FileMode.append);
      } catch (retryError) {
        Logger.getSelfLogger()?.logError('Failed to write after recreating file: $retryError');
      }
    }
  }

  Future<void> checkForFileChange() async {
    var now = DateTime.now();
    var create = false;

    switch (rotationCycle) {
      case RotationCycle.NEVER:
        return;
      case RotationCycle.DAY:
        if (now.year > created.year || now.month > created.month) {
          create = true;
        } else if (now.day > created.day) {
          create = true;
        }
        break;
      case RotationCycle.WEEK:
        if (now.year > created.year) {
          create = true;
        } else if (Utils.getCalendarWeek(now) > Utils.getCalendarWeek(created)) {
          create = true;
        }
        break;
      case RotationCycle.MONTH:
        if (now.year > created.year) {
          create = true;
        } else if (now.month > created.month) {
          create = true;
        }
        break;
      case RotationCycle.YEAR:
        if (now.year > created.year) {
          create = true;
        }
        break;
    }

    if (create) {
      created = now;
      _ensurePathExists();
      Logger.getSelfLogger()?.logInfo('Rotated log file for pattern: $filePattern');
    }
  }

  @override
  String toString() {
    return 'FileAppender(filePattern: $filePattern, fileExtension: $fileExtension, '
        'path: $path, rotationCycle: $rotationCycle, created: $created, '
        'enabled: $enabled, level: $level, format: $format, dateFormat: $dateFormat)';
  }

  @override
  String getType() {
    return 'FILE';
  }

  @override
  Future<void> dispose() async {
    // file ops are atomic already
  }

  @override
  Future<void> flush() async {
    // file ops are atomic already
  }
}
