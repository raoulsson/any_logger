import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:intl/intl.dart';

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';
import '../utils.dart';

class FileAppender extends Appender {
  String? filePattern;

  String fileExtension = 'log';

  String path = '';

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

    if (!test) {
      if (FileSystemEntity.typeSync(_getFullFilename()) ==
          FileSystemEntityType.notFound) {
        File(_getFullFilename()).createSync();
      }
      _file = File(_getFullFilename());
    }
  }

  String _getFullFilename() {
    switch (rotationCycle) {
      case RotationCycle.NEVER:
        return path + filePattern! + '.' + fileExtension;
      case RotationCycle.DAY:
        return path +
            filePattern! +
            '_' +
            DateFormat('yyyy-MM-dd').format(created) +
            '.' +
            fileExtension;
      case RotationCycle.WEEK:
        return path +
            filePattern! +
            '_' +
            created.year.toString() +
            '-CW' +
            DateUtils.getCalendarWeek(created).toString() +
            '.' +
            fileExtension;
      case RotationCycle.MONTH:
        return path +
            filePattern! +
            '_' +
            DateFormat('yyyy-MM').format(created) +
            '.' +
            fileExtension;
      case RotationCycle.YEAR:
        return path +
            filePattern! +
            '_' +
            DateFormat('yyyy').format(created) +
            '.' +
            fileExtension;
    }
  }

  @override
  void append(LogRecord logRecord) async {
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
    _file.writeAsStringSync(
        LogRecordFormatter.format(logRecord, format, dateFormat: dateFormat) +
            '\n',
        mode: FileMode.append);
    if (logRecord.stackTrace != null) {
      _file.writeAsStringSync(logRecord.stackTrace.toString() + '\n',
          mode: FileMode.append);
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
        } else if (DateUtils.getCalendarWeek(now) >
            DateUtils.getCalendarWeek(created)) {
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
      _file = await File(_getFullFilename()).create();
    }
  }

  @override
  String toString() {
    return super.toString();
  }

  @override
  String getType() {
    return AppenderType.FILE.name;
  }
}
