import '../../any_logger_lib.dart';

enum AppenderType {
  CONSOLE,
  FILE,
  JSON_HTTP,
  EMAIL,
  MYSQL;

  Appender createAppender() {
    switch (this) {
      case AppenderType.CONSOLE:
        return ConsoleAppender();
      case AppenderType.FILE:
        return FileAppender();
      case AppenderType.JSON_HTTP:
        return JsonHttpAppender();
      case AppenderType.EMAIL:
        return EmailAppender();
      case AppenderType.MYSQL:
        return MySqlAppender();
    }
  }

  Future<Appender> createFromConfig(Map<String, dynamic> config,
      {bool test = false, DateTime? date}) async {
    switch (this) {
      case AppenderType.CONSOLE:
        return ConsoleAppender.fromConfig(config, test: test, date: date);
      case AppenderType.FILE:
        return FileAppender.fromConfig(config, test: test, date: date);
      case AppenderType.JSON_HTTP:
        return JsonHttpAppender.fromConfig(config, test: test, date: date);
      case AppenderType.EMAIL:
        return EmailAppender.fromConfig(config, test: test, date: date);
      case AppenderType.MYSQL:
        var appender = MySqlAppender.fromConfig(config, test: test, date: date);
        if (!test) {
          await appender.initialize();
        }
        return appender;
    }
  }
}
