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

  static Future<FileAppender> fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date}) async {
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
      appender.rotationCycle =
          RotationCycle.fromString(config['rotationCycle']);
    }

    if (config.containsKey('path')) {
      appender.path = config['path'];
    }

    // Resolve the base path once during initialization
    if (getAppDocumentsDirectoryFnc != null) {
      final dir = await getAppDocumentsDirectoryFnc!();
      appender._resolvedBasePath = dir.path;
    }

    appender.ensurePathExists();

    return appender;
  }

  static FileAppender fromConfigSync(Map<String, dynamic> config,
      {bool test = false, DateTime? date}) {
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
      appender.rotationCycle =
          RotationCycle.fromString(config['rotationCycle']);
    }

    if (config.containsKey('path')) {
      appender.path = config['path'];
    }

    // Note: Sync version cannot resolve Flutter paths
    appender.ensurePathExists();

    return appender;
  }

  /// Ensures the directory and file exist
  void ensurePathExists() {
    final fullPath = getFullFilename();
    final file = File(fullPath);

    final directory = file.parent;
    if (!directory.existsSync()) {
      try {
        Logger.getSelfLogger()
            ?.logInfo('Creating directory: ${directory.absolute.path}');
        directory.createSync(recursive: true);
        Logger.getSelfLogger()?.logInfo(
            'Successfully created directory: ${directory.absolute.path}');
      } catch (e) {
        Logger.getSelfLogger()?.logError(
            'Failed to create directory: ${directory.absolute.path}: $e');
        // Try with absolute path
        try {
          final absDir = Directory(directory.absolute.path);
          absDir.createSync(recursive: true);
          Logger.getSelfLogger()?.logInfo(
              'Created directory using absolute path: ${absDir.path}');
        } catch (e2) {
          Logger.getSelfLogger()
              ?.logError('Failed even with absolute path: $e2');
          throw Exception(
              'Cannot create log directory: ${directory.path}. Error: $e');
        }
      }
    }

    if (!file.existsSync()) {
      try {
        Logger.getSelfLogger()
            ?.logInfo('Creating log file: ${file.absolute.path}');
        file.createSync();
        Logger.getSelfLogger()
            ?.logInfo('Successfully created log file: ${file.absolute.path}');
      } catch (e) {
        Logger.getSelfLogger()
            ?.logError('Failed to create log file: ${file.absolute.path}: $e');
        throw Exception(
            'Cannot create log file: ${file.absolute.path}. Error: $e');
      }
    }

    _file = file;

    // Final verification
    if (!_file.existsSync()) {
      throw Exception(
          'File was not created successfully: ${_file.absolute.path}');
    }
    if (!_file.parent.existsSync()) {
      throw Exception(
          'Directory was not created successfully: ${_file.parent.absolute.path}');
    }
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
    copy.ensurePathExists();
    return copy;
  }

  String getFullFilename() {
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
    if (fullPath.isNotEmpty &&
        !fullPath.endsWith('/') &&
        !fullPath.endsWith('\\')) {
      fullPath += '/';
    }

    // Use the enhanced rotation cycle to get filename suffix
    final suffix = rotationCycle.getFilenameSuffix(created);
    return '$fullPath$filePattern$suffix.$fileExtension';
  }

  @override
  void append(LogRecord logRecord) {
    if (!enabled) return;

    // Check for rotation using new logic
    if (rotationCycle != RotationCycle.NEVER) {
      checkForFileChange();
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
      try {
        ensurePathExists();
        _file.writeAsStringSync(
            '${LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat)}\n',
            mode: FileMode.append);
      } catch (retryError) {
        Logger.getSelfLogger()
            ?.logError('Failed to write after recreating file: $retryError');
      }
    }
  }

  void checkForFileChange() {
    if (rotationCycle.shouldRotate(created)) {
      created = DateTime.now();
      ensurePathExists();
      Logger.getSelfLogger()?.logInfo(
          'Rotated log file for pattern: $filePattern (${rotationCycle.name})');
    }
  }

  @override
  String toString() {
    return 'FileAppender(filePattern: $filePattern, fileExtension: $fileExtension, '
        'path: $path, rotationCycle: ${rotationCycle.name}, created: $created, '
        'enabled: $enabled, level: $level, format: $format, dateFormat: $dateFormat)';
  }

  String? get resolvedBasePath => _resolvedBasePath;

  set resolvedBasePath(String? value) => _resolvedBasePath = value;

  File get file => _file;

  @override
  String getType() {
    return 'FILE';
  }

  @override
  String getShortConfigDesc() {
    return 'logPath: ${_resolvedBasePath ?? ""}$path, rotation: ${rotationCycle.name}';
  }

  @override
  Future<void> dispose() async {
    // file ops are atomic already
  }

  @override
  Future<void> flush() async {
    // file ops are atomic already
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = super.getConfig();
    config.addAll({
      'filePattern': filePattern,
      'fileExtension': fileExtension,
      'path': path,
      'rotationCycle': rotationCycle.name,
      'resolvedBasePath': _resolvedBasePath,
      'fullFilePath': getFullFilename(),
      'fileExists': _file.existsSync(),
      'fileAbsolutePath': _file.absolute.path,
    });
    return config;
  }
}
