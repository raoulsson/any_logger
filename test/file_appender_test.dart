import 'dart:io';

import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  test('Test FileAppender daily rotating', () async {
    var config = {
      'appenders': [
        {
          'type': 'FILE',
          'format': '[%d][%i][%t][%l][%c] %m [%f]',
          'level': 'INFO',
          'filePattern': 'unittest',
          'fileExtension': 'txt',
          'path': '',
          'rotationCycle': 'DAY'
        }
      ],
    };
    var yesterday = DateTime.now().subtract(Duration(days: 1));
    var now = DateTime.now();
    var yesterdayAsString = DateFormat('yyyy-MM-dd').format(yesterday);
    var nowAsString = DateFormat('yyyy-MM-dd').format(now);
    await LoggerFactory.init(null);
    LoggerFactory.getRootLogger().registerAllAppender([FileAppender()]);
    await LoggerFactory.init(config, date: yesterday);
    if (FileSystemEntity.typeSync('unittest_$yesterdayAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('Initial file not found!');
    }
    try {
      File('unittest_$yesterdayAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$yesterdayAsString.txt"');
    }
    Logger.info(tag: 'UnitTest', 'Hello World');
    await Future.delayed(Duration(seconds: 2));
    if (FileSystemEntity.typeSync('unittest_$nowAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('New file "unittest_$nowAsString.txt" not found!');
    }
    try {
      File('unittest_$nowAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$nowAsString.txt"');
    }
  });

  test('Test FileAppender weekly rotating', () async {
    var config = {
      'appenders': [
        {
          'type': 'FILE',
          'format': '[%d][%i][%t][%l][%c] %m [%f]',
          'level': 'INFO',
          'filePattern': 'unittest',
          'fileExtension': 'txt',
          'path': '',
          'rotationCycle': 'WEEK'
        }
      ],
    };
    var lastWeek = DateTime.now().subtract(Duration(days: 7));
    var now = DateTime.now();
    var lastWeekAsString = lastWeek.year.toString() +
        '-CW' +
        DateUtils.getCalendarWeek(lastWeek).toString();
    var nowAsString =
        now.year.toString() + '-CW' + DateUtils.getCalendarWeek(now).toString();
    LoggerFactory.getRootLogger().registerAllAppender([FileAppender()]);
    await LoggerFactory.init(config, date: lastWeek);
    if (FileSystemEntity.typeSync('unittest_$lastWeekAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('Initial file not found!');
    }
    try {
      File('unittest_$lastWeekAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$lastWeekAsString.txt"');
    }
    Logger.info(tag: 'UnitTest', 'Hello World');
    await Future.delayed(Duration(seconds: 2));
    if (FileSystemEntity.typeSync('unittest_$nowAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('New file "unittest_$nowAsString.txt" not found!');
    }
    try {
      File('unittest_$nowAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$nowAsString.txt"');
    }
  });

  test('Test FileAppender monthly rotating', () async {
    var config = {
      'appenders': [
        {
          'type': 'FILE',
          'format': '[%d][%i][%t][%l][%c] %m [%f]',
          'level': 'INFO',
          'filePattern': 'unittest',
          'fileExtension': 'txt',
          'path': '',
          'rotationCycle': 'MONTH'
        }
      ],
    };

    var now = DateTime.now();
    var lastMonth = DateTime(
        now.year, now.month - 1, now.day, now.hour, now.minute, now.second);
    var lastMonthAsString = DateFormat('yyyy-MM').format(lastMonth);
    var nowAsString = DateFormat('yyyy-MM').format(now);
    LoggerFactory.getRootLogger().registerAllAppender([FileAppender()]);
    await LoggerFactory.init(config, date: lastMonth);
    if (FileSystemEntity.typeSync('unittest_$lastMonthAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('Initial file not found!');
    }
    try {
      File('unittest_$lastMonthAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$lastMonthAsString.txt"');
    }
    Logger.info(tag: 'UnitTest', 'Hello World');
    await Future.delayed(Duration(seconds: 2));
    if (FileSystemEntity.typeSync('unittest_$nowAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('New file "unittest_$nowAsString.txt" not found!');
    }
    try {
      File('unittest_$nowAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$nowAsString.txt"');
    }
  });

  test('Test FileAppender yearly rotating', () async {
    var config = {
      'appenders': [
        {
          'type': 'FILE',
          'format': '[%d][%i][%t][%l][%c] %m [%f]',
          'level': 'INFO',
          'filePattern': 'unittest',
          'fileExtension': 'txt',
          'path': '',
          'rotationCycle': 'YEAR'
        }
      ],
    };

    var now = DateTime.now();
    var lastYear = DateTime(
        now.year - 1, now.month, now.day, now.hour, now.minute, now.second);
    var lastYearAsString = DateFormat('yyyy').format(lastYear);
    var nowAsString = DateFormat('yyyy').format(now);
    LoggerFactory.getRootLogger().registerAllAppender([FileAppender()]);
    await LoggerFactory.init(config, date: lastYear);
    if (FileSystemEntity.typeSync('unittest_$lastYearAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('Initial file not found!');
    }
    try {
      File('unittest_$lastYearAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$lastYearAsString.txt"');
    }
    Logger.info(tag: 'UnitTest', 'Hello World');
    await Future.delayed(Duration(seconds: 2));
    if (FileSystemEntity.typeSync('unittest_$nowAsString.txt') ==
        FileSystemEntityType.notFound) {
      fail('New file "unittest_$nowAsString.txt" not found!');
    }
    try {
      File('unittest_$nowAsString.txt').deleteSync();
    } on FileSystemException {
      fail('Can not remove file with name "unittest_$nowAsString.txt"');
    }
  });
}
