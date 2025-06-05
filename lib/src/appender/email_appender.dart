import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../any_logger_lib.dart';
import '../log_record_formatter.dart';

class EmailAppender extends Appender {
  String? host;
  String? user;
  String? password;
  int? port;
  String? fromMail;
  String? fromName;
  late List<Address> to;
  List<Address>? toCC;
  List<Address>? toBCC;
  bool ssl = false;
  late SmtpServer _smtpServer;
  late PersistentConnection _connection;
  String? templateFile;
  String? template;
  bool html = false;

  EmailAppender() : super();

  EmailAppender.fromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date})
      : super(customDate: date) {
    initializeCommonProperties(config, test: test, date: date);

    if (config.containsKey('host')) {
      host = config['host'];
    } else {
      throw ArgumentError('Missing host argument for EmailAppender');
    }

    if (config.containsKey('user')) {
      user = config['user'];
    }

    if (config.containsKey('password')) {
      password = config['password'];
    }

    if (config.containsKey('port')) {
      port = config['port'];
    } else {
      throw ArgumentError('Missing port argument for EmailAppender');
    }

    if (config.containsKey('fromMail')) {
      fromMail = config['fromMail'];
    } else {
      fromMail = user;
    }

    if (config.containsKey('fromName')) {
      fromName = config['fromName'];
    } else {
      fromName = user;
    }

    if (config.containsKey('to')) {
      to = [];
      for (String s in config['to']) {
        to.add(Address(s));
      }
    } else {
      throw ArgumentError('Missing to argument for EmailAppender');
    }

    if (config.containsKey('toCC')) {
      toCC = [];
      for (String s in config['toCC']) {
        toCC!.add(Address(s));
      }
    }

    if (config.containsKey('toBCC')) {
      toBCC = [];
      for (String s in config['toBCC']) {
        toBCC!.add(Address(s));
      }
    }

    if (config.containsKey('ssl')) {
      ssl = config['ssl'];
    }

    if (config.containsKey('html')) {
      html = config['html'];
    }

    if (!test) {
      _smtpServer = SmtpServer(host!,
          port: port!, username: user, password: password, ssl: ssl);
      _connection = PersistentConnection(_smtpServer);
    }

    if (config.containsKey('templateFile')) {
      templateFile = config['templateFile'];
      var file = File(templateFile!);
      template = file.readAsStringSync();
    }
  }

  @override
  void append(LogRecord logRecord) async {
    logRecord.loggerName ??= getType().toString();
    final message = Message()
      ..from = Address(fromMail!, fromName)
      ..recipients.addAll(to)
      ..subject =
          'Logger ${logRecord.level} at ${logRecord.getFormattedTime()}';
    if (html) {
      message.html = LogRecordFormatter.formatEmail(template, logRecord,
          dateFormat: dateFormat);
    } else {
      message.text = LogRecordFormatter.formatEmail(template, logRecord,
          dateFormat: dateFormat);
    }

    if (IterableUtils.isNotNullOrEmpty(toCC)) {
      message.ccRecipients.addAll(toCC!);
    }
    if (IterableUtils.isNotNullOrEmpty(toBCC)) {
      message.bccRecipients.addAll(toBCC!);
    }

    try {
      await _connection.send(message);
    } catch (e) {
      print(e);
      return;
    }
  }

  @override
  String toString() {
    return super.toString() + ' ' + 'EmailAppender(host: $host, user: $user, password: $password, port: $port, fromMail: $fromMail, fromName: $fromName, to: $to, toCC: $toCC, toBCC: $toBCC, ssl: $ssl, html: $html, created: $created, enabled: $enabled)';
  }

  @override
  String getType() {
    return AppenderType.EMAIL.name;
  }

  @override
  Future<void> dispose() async {
    // tbd
  }

  @override
  Future<void> flush() async {
    // tbd
  }
}
