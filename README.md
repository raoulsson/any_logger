# Log 4 Dart 3

Forked from https://github.com/Ephenodrom/Dart-Log-4-Dart-2

## MDC

MDC (Mapped Diagnostic Context) is a mechanism that allows you to add contextual information to your 
log messages. This can be useful for tracking the state of your application at the time of logging.

To use it, you can set values in the MDC before logging a message. For example, you can set a user ID or session ID
to help identify the source of the log message. You can also use MDC to add other contextual information, such as
the current request ID or transaction ID.

You have to setup a zone and store the values in the zone. The MDC can then be accessed by the logger.

The format in the log string pattern is `%X{key}`. The key is the name of the value you want to log.

### Example

Here we configure two keys: 

- %X{logging.device-hash}
- %X{logging.session-hash}

```dart
const kLog4DartConfig = {
  'appenders': [
    {
      'type': 'CONSOLE',
      'format': '[%d][%X{logging.device-hash}][%X{logging.session-hash}][%l][%c] %m [%f]',
      'level': 'DEBUG',
      'dateFormat': 'HH:mm:ss.SSS',
      'mode': 'stdout',
    }
  ],
};
```
The logger will find the pattern `%X{logging.device-hash}` and `[%X{logging.session-hash}]` in the 
format string and replace it with the values stored in the zone.

Thus you need to set the values in the zone before logging. 

```dart
  runZonedGuarded(
        ...
        runApp(multiProvider);
        ...
        zoneValues: {
          'logging.device-hash': [LoggingIdentifiers.getDeviceHash()],
          'logging.session-hash': [LoggingIdentifiers.getSessionHash()],
        },
    );
```
You have to generate the desired values for yourself or use the static methods in the LoggingIdentifiers 
class, if these fit your use case.

For more information see: (https://logging.apache.org/log4j/2.x/manual/thread-context.html)[https://logging.apache.org/log4j/2.x/manual/thread-context.html]


## Copyright And License (Previous)

MIT License

Copyright (c) 2020 Ephenodrom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


## Copyright And License

Copyright 2025 Raoul Marc Schmidiger (hello@raoulsson.com)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the “Software”),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.