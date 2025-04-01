import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';
import 'package:test/test.dart';

void main() {
  test('Test init()', () async {
    var config = {
      'appenders': [
        {'type': 'CONSOLE', 'format': '%d %t %l %m', 'level': 'INFO'},
        {
          'type': 'FILE',
          'format': '%d %t %l %m',
          'level': 'INFO',
          'filePattern': 'anylog',
          'fileExtension': 'txt',
          'path': '/path/to/'
        },
        {
          'type': 'EMAIL',
          'level': 'INFO',
          'host': 'smtp.test.de',
          'user': 'test@test.de',
          'password': 'test',
          'port': 1,
          'fromMail': 'test@test.de',
          'fromName': 'Jon Doe',
          'to': ['test1@example.com', 'test2@example.com'],
          'toCC': ['test1@example.com', 'test2@example.com'],
          'toBCC': ['test1@example.com', 'test2@example.com']
        },
        {
          'type': 'JSON_HTTP',
          'level': 'INFO',
          'url': 'api.example.com',
          'headers': ['Content-Type:application/json']
        },
        {
          'type': 'MYSQL',
          'level': 'INFO',
          'host': 'database.example.com',
          'user': 'admin',
          'password': 'test',
          'port': 1,
          'database': 'mydatabase',
          'table': 'log_entries'
        }
      ],
    };
    await LoggerFactory.init(null);
    LoggerFactory.getRootLogger().registerAllAppender([
      ConsoleAppender(),
      FileAppender(),
      JsonHttpAppender(),
      EmailAppender(),
      MySqlAppender()
    ]);
    await LoggerFactory.init(config, test: true);

    expect(LoggerFactory.getRootLogger().appenders.length, 5);

    var console =
        LoggerFactory.getRootLogger().appenders.elementAt(0) as ConsoleAppender;
    expect(console.getType(), AppenderType.CONSOLE.name);
    expect(console.format, '%d %t %l %m');
    expect(console.level, Level.INFO);

    var file =
        LoggerFactory.getRootLogger().appenders.elementAt(1) as FileAppender;

    expect(file.getType(), AppenderType.FILE.name);
    expect(file.format, '%d %t %l %m');
    expect(file.level, Level.INFO);
    expect(file.filePattern, 'anylog');
    expect(file.rotationCycle, RotationCycle.NEVER);
    expect(file.path, '/path/to/');

    var email =
        LoggerFactory.getRootLogger().appenders.elementAt(2) as EmailAppender;

    expect(email.getType(), AppenderType.EMAIL.name);
    expect(email.level, Level.INFO);
    expect(email.host, 'smtp.test.de');
    expect(email.user, 'test@test.de');
    expect(email.password, 'test');
    expect(email.port, 1);
    expect(email.fromMail, 'test@test.de');
    expect(email.fromName, 'Jon Doe');
    expect(email.to.length, 2);
    expect(email.toCC!.length, 2);
    expect(email.toBCC!.length, 2);

    var http = LoggerFactory.getRootLogger().appenders.elementAt(3)
        as JsonHttpAppender;

    expect(http.getType(), AppenderType.JSON_HTTP.name);
    expect(http.level, Level.INFO);
    expect(http.url, 'api.example.com');
    expect(http.headers.length, 1);
    expect(http.headers['Content-Type'], 'application/json');

    var mysql =
        LoggerFactory.getRootLogger().appenders.elementAt(4) as MySqlAppender;

    expect(mysql.getType(), AppenderType.MYSQL.name);
    expect(mysql.level, Level.INFO);
    expect(mysql.host, 'database.example.com');
    expect(mysql.user, 'admin');
    expect(mysql.password, 'test');
    expect(mysql.port, 1);
    expect(mysql.database, 'mydatabase');
  });
}
