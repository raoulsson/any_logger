import 'package:any_logger/any_logger_lib.dart';
import 'package:any_logger/src/logger_factory.dart';

void main() {
  var config = {
    'appenders': [
      {'type': 'CONSOLE', 'format': '%d %t %l %m', 'level': 'INFO'},
    ]
  };
  LoggerFactory.init(config);
  ExampleClass.doSomething();
}

class ExampleClass {
  static String TAG = 'ExampleClass';

  static void doSomething() {
    Logger.info('I am doing something!');
  }
}
