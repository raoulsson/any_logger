import 'package:any_logger/any_logger_lib.dart';

Future<void> main() async {
  var config = {
    'appenders': [
      {'type': 'CONSOLE', 'format': '%d %t %l %m', 'level': 'INFO'},
    ]
  };
  await LoggerFactory.init(config);
  ExampleClass.doSomething();
}

class ExampleClass {
  static String TAG = 'ExampleClass';

  static void doSomething() {
    Logger.info('I am doing something!');
  }
}
