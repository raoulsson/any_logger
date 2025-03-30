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

- logging.device-hash
- logging.session-hash


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

The logger will find the pattern: `%X{logging.device-hash}` and `[%X{logging.session-hash}]` in the 
format string and replace it with the values stored in the zone.

Thus you need to set the values in the zone before logging. 

```dart
  runZonedGuarded(
        ...
        runApp(multiProvider);
        ...
        zoneValues: {
            'logging.device-hash': [await LoggingIdentifiers.getDeviceHash(kLogHashLength)],
            'logging.session-hash': [await LoggingIdentifiers.getSessionHash(kLogHashLength)],
        },
    );
```

This will output something like this:

```
[18:33:17.042][919d15][700442][DEBUG][LightController.fireColorChangeEvent:335] Color changed event: LightColor{red: 255, green: 255, blue: 255} [package:gemma_app/model/light_controller.dart(335:5)]
[18:33:17.043][919d15][700442][DEBUG][Light.fireSwitchChangeEvent:83] On/Off changed event: true [package:gemma_app/model/light.dart(83:5)]
```

You have to generate the desired hash values for yourself or implement something along these lines:

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart'; // You'll need to add this package

class LoggingIdentifiers {
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  // Cache the values so they remain consistent during app runtime
  static String? _deviceHash;
  static String? _sessionHash;

  /// Generates or returns a cached device fingerprint hash (8 digits)
  static Future<String> getDeviceHash(int length) async {
    if (_deviceHash != null) return _deviceHash!;

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceData = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData =
        '${androidInfo.model}-${androidInfo.id}-${androidInfo.brand}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = '${iosInfo.model}-${iosInfo.identifierForVendor}';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        deviceData = '${macOsInfo.model}-${macOsInfo.computerName}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceData = '${windowsInfo.computerName}-${windowsInfo.deviceId}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceData = '${linuxInfo.name}-${linuxInfo.version}';
      } else {
        // Fallback for web or other platforms
        deviceData = '${Platform.operatingSystem}-${Platform.localHostname}';
      }
    } catch (e) {
      // Handle any exceptions that may occur while retrieving device info
      print('Error retrieving device info: $e');
      deviceData = 'UnknownDevice or Simulator';
    }

    // Generate an 8-digit hash from the device data
    _deviceHash = _generateMd5(deviceData, length);
    return _deviceHash!;
  }

  /// Generates or returns a cached random session hash (8 digits)
  static String getSessionHash(int length) {
    if (_sessionHash != null) return _sessionHash!;

    final rnd = Random();
    final randomString = String.fromCharCodes(Iterable.generate(length * 5, (_) => LoggingIdentifiers._chars.codeUnitAt(rnd.nextInt(LoggingIdentifiers._chars.length))));
    _sessionHash = _generateMd5(randomString, length);
    return _sessionHash!;
  }

  /// Generates a deterministic hash of specified length from input
  static String _generateMd5(String input, int length) {
    return md5.convert(utf8.encode(input)).toString().substring(0, length);
  }
}
```

For more information see: [https://logging.apache.org/log4j/2.x/manual/thread-context.html]


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

### Previous: Copyright And License: [MIT License by Ephenodrom](https://github.com/Ephenodrom/Dart-Log-4-Dart-2/blob/master/LICENSE)
