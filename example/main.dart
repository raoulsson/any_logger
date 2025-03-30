import 'package:any_logger/any_logger_lib.dart';

void main() {
  var config = {
    'appenders': [
      {'type': 'CONSOLE', 'format': '%d %t %l %m', 'level': 'INFO'},
    ]
  };
  Logger.init(config);
  ExampleClass.doSomething();
}

class ExampleClass {
  static String TAG = 'ExampleClass';

  static void doSomething() {
    Logger.info('I am doing something!');
  }
}
