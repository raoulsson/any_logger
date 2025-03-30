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
You have to generate the desired values for yourself or implement something along these lines:

```dart
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart'; // You'll need to add this package

class LoggingIdentifiers {
  // Cache the values so they remain consistent during app runtime
  static String? _deviceHash;
  static String? _sessionHash;

  /// Generates or returns a cached device fingerprint hash (8 digits)
  static Future<String> getDeviceHash() async {
    if (_deviceHash != null) return _deviceHash!;

    final deviceInfo = DeviceInfoPlugin();
    String deviceData = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = '${androidInfo.model}-${androidInfo.id}-${androidInfo.brand}';
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
      // Fallback if device_info fails
      deviceData = '${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Generate an 8-digit hash from the device data
    _deviceHash = _generateHash(deviceData, 8);
    return _deviceHash!;
  }

  /// Generates or returns a cached random session hash (8 digits)
  static String getSessionHash() {
    if (_sessionHash != null) return _sessionHash!;

    // Generate a random session hash
    _sessionHash = _generateRandomHash(8);
    return _sessionHash!;
  }

  /// Generates a deterministic hash of specified length from input
  static String _generateHash(String input, int length) {
    // Simple hash function - you could use a more sophisticated one if needed
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash + input.codeUnitAt(i)) % 100000000; // Keep it to 8 digits max
    }

    // Ensure it's exactly the right length by padding with zeros
    return hash.toString().padLeft(length, '0').substring(0, length);
  }

  /// Generates a random hash of specified length
  static String _generateRandomHash(int length) {
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.write(random.nextInt(10)); // Add random digit (0-9)
    }

    return buffer.toString();
  }
}
```

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