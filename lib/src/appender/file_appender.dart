import 'dart:io';

import '../../any_logger.dart';

class FileAppender extends Appender {
  String? filePattern;
  String fileExtension = 'log';
  String path = 'logs/';
  RotationCycle rotationCycle = RotationCycle.NEVER;
  late File _file;

  FileAppender() : super();

  FileAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('filePattern')) {
      filePattern = config['filePattern'];
    } else {
      throw ArgumentError('Missing file argument for file appender');
    }

    if (config.containsKey('fileExtension')) {
      fileExtension = config['fileExtension'];
    }

    if (config.containsKey('rotationCycle')) {
      rotationCycle = Utils.getRotationCycleFromString(config['rotationCycle']);
    }

    if (config.containsKey('path')) {
      path = config['path'];
    }

    _ensurePathExists();
  }

  /// Ensures the directory and file exist
  void _ensurePathExists() {
    final fullPath = _getFullFilename();
    final file = File(fullPath);

    // Create directory if it doesn't exist
    final directory = file.parent;
    if (!directory.existsSync()) {
      try {
        directory.createSync(recursive: true);
        Logger.getSelfLogger()
            ?.logDebug('Created directory: ${directory.path}');
      } catch (e) {
        Logger.getSelfLogger()
            ?.logError('Failed to create directory: ${directory.path}: $e');
        throw Exception('Cannot create log directory: ${directory.path}');
      }
    }

    // Create file if it doesn't exist
    if (!file.existsSync()) {
      try {
        file.createSync();
        Logger.getSelfLogger()?.logDebug('Created log file: $fullPath');
      } catch (e) {
        Logger.getSelfLogger()
            ?.logError('Failed to create log file: $fullPath: $e');
        throw Exception('Cannot create log file: $fullPath');
      }
    }

    _file = file;
  }

  @override
  Appender createDeepCopy() {
    FileAppender copy = FileAppender();
    copyBasePropertiesTo(copy); // Use helper
    copy.filePattern = filePattern;
    copy.fileExtension = fileExtension;
    copy.path = path;
    copy.rotationCycle = rotationCycle;
    copy._ensurePathExists();
    return copy;
  }

  String _getFullFilename() {
    // Ensure path ends with separator if it's not empty
    String finalPath = path;
    if (finalPath.isNotEmpty &&
        !finalPath.endsWith('/') &&
        !finalPath.endsWith('\\')) {
      // Use forward slash for cross-platform compatibility
      finalPath += '/';
    }

    switch (rotationCycle) {
      case RotationCycle.NEVER:
        return '$finalPath${filePattern!}.$fileExtension';
      case RotationCycle.DAY:
        // Use SimpleDateFormat instead of intl's DateFormat
        return '$finalPath${filePattern!}_${SimpleDateFormat('yyyy-MM-dd').format(created)}.$fileExtension';
      case RotationCycle.WEEK:
        return '$finalPath${filePattern!}_${created.year}-CW${Utils.getCalendarWeek(created)}.$fileExtension';
      case RotationCycle.MONTH:
        // Use SimpleDateFormat instead of intl's DateFormat
        return '$finalPath${filePattern!}_${SimpleDateFormat('yyyy-MM').format(created)}.$fileExtension';
      case RotationCycle.YEAR:
        // Use SimpleDateFormat instead of intl's DateFormat
        return '$finalPath${filePattern!}_${SimpleDateFormat('yyyy').format(created)}.$fileExtension';
    }
  }

  @override
  void append(LogRecord logRecord) async {
    if (!enabled) return;

    switch (rotationCycle) {
      case RotationCycle.NEVER:
        // Do nothing
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
      _file.writeAsStringSync(
          '${LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat)}\n',
          mode: FileMode.append);

      if (logRecord.stackTrace != null) {
        _file.writeAsStringSync('${logRecord.stackTrace}\n',
            mode: FileMode.append);
      }
    } catch (e) {
      Logger.getSelfLogger()?.logError('Failed to write to log file: $e');
      // Try to recreate the file
      try {
        _ensurePathExists();
        // Retry the write
        _file.writeAsStringSync(
            '${LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat)}\n',
            mode: FileMode.append);
      } catch (retryError) {
        Logger.getSelfLogger()
            ?.logError('Failed to write after recreating file: $retryError');
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
        } else if (Utils.getCalendarWeek(now) >
            Utils.getCalendarWeek(created)) {
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
