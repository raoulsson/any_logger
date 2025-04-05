# Any Logger

Forked from https://github.com/Ephenodrom/Dart-Log-4-Dart-2

## MDC

MDC (Mapped Diagnostic Context) is a mechanism that allows you to add contextual information to your
log messages. This can be useful for tracking the state of your application at the time of logging.

To use it, you can set values in the MDC before logging a message. For example, you can set a user
ID or session ID
to help identify the source of the log message. You can also use MDC to add other contextual
information, such as
the current request ID or transaction ID.

You have to setup a zone and store the values in the zone. The MDC can then be accessed by the
logger.

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
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceFingerprint {
  static String? _deviceHash;
  static String? _sessionHash;
  static const int DEFAULT_HASH_LENGTH = 8;

  /// Gets or generates a device fingerprint that tries to be as unique as possible
  static Future<String> getDeviceHash({int length = DEFAULT_HASH_LENGTH}) async {
    if (_deviceHash != null) return _deviceHash!;

    try {
      final List<String> identifiers = await _gatherDeviceIdentifiers();
      final String combinedData = identifiers.join('-');

      // Generate the hash
      _deviceHash = _generateMd5(combinedData, length);
      return _deviceHash!;
    } catch (e) {
      debugPrint('Error generating device hash: $e');
      // Fallback to a less reliable but still somewhat stable hash
      return _generateFallbackHash(length);
    }
  }

  /// Gathers as many device identifiers as possible
  static Future<List<String>> _gatherDeviceIdentifiers() async {
    final List<String> identifiers = [];
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    // Get basic device info
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      identifiers.add(iosInfo.model ?? 'unknown_model');
      identifiers.add(iosInfo.systemName ?? 'unknown_os');
      identifiers.add(iosInfo.systemVersion ?? 'unknown_version');
      identifiers.add(iosInfo.name ?? 'unknown_name');
      identifiers.add(iosInfo.identifierForVendor ?? 'unknown_vendor_id');

      // Get additional data that might vary between devices
      identifiers.add(iosInfo.utsname.machine ?? 'unknown_machine');
      identifiers.add(iosInfo.utsname.nodename ?? 'unknown_node');
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      identifiers.add(androidInfo.model);
      identifiers.add(androidInfo.id);
      identifiers.add(androidInfo.brand);
      identifiers.add(androidInfo.device);
      identifiers.add(androidInfo.hardware);
      identifiers.add(androidInfo.fingerprint);
    } else {
      // Handle other platforms...
      identifiers.add(Platform.operatingSystem);
      identifiers.add(Platform.localHostname);
    }

    // Try to get app storage info which should be somewhat unique
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String appPath = appDir.path;
      identifiers.add(appPath);

      // Stat the directory to get info like creation time
      final pathStat = await Directory(appPath).stat();
      identifiers.add(pathStat.modified.millisecondsSinceEpoch.toString());
    } catch (e) {
      debugPrint('Error accessing app directory: $e');
    }

    // Get screen metrics which can vary between devices
    try {
      final screenWidth = await _getScreenWidth();
      final screenHeight = await _getScreenHeight();
      identifiers.add('${screenWidth}x${screenHeight}');
    } catch (e) {
      debugPrint('Error getting screen metrics: $e');
    }

    // Generate and save a semi-persistent ID to app storage if one doesn't exist
    try {
      final String persistentId = await _getOrCreatePersistentId();
      identifiers.add(persistentId);
    } catch (e) {
      debugPrint('Error with persistent ID: $e');
    }

    return identifiers;
  }

  /// Gets screen width using platform channel
  static Future<double> _getScreenWidth() async {
    try {
      const channel = MethodChannel('com.yourapp.device_metrics');
      return await channel.invokeMethod('getScreenWidth');
    } catch (e) {
      // Fallback method
      return 0;
    }
  }

  /// Gets screen height using platform channel
  static Future<double> _getScreenHeight() async {
    try {
      const channel = MethodChannel('com.yourapp.device_metrics');
      return await channel.invokeMethod('getScreenHeight');
    } catch (e) {
      // Fallback method
      return 0;
    }
  }

  /// Creates or retrieves a persistent ID stored in app storage
  static Future<String> _getOrCreatePersistentId() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final File idFile = File('${appDir.path}/.device_id');

      if (await idFile.exists()) {
        return await idFile.readAsString();
      } else {
        // Generate a new ID
        final String newId = _generateRandomString(32);
        await idFile.writeAsString(newId);
        return newId;
      }
    } catch (e) {
      return _generateRandomString(16); // Fallback to a session-only ID
    }
  }

  /// Generates a random string of specified length
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
        Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)))
    );
  }

  /// Generates a session hash that changes each app launch
  static String getSessionHash({int length = DEFAULT_HASH_LENGTH}) {
    if (_sessionHash != null) return _sessionHash!;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomStr = _generateRandomString(16);
    _sessionHash = _generateMd5('$timestamp-$randomStr', length);
    return _sessionHash!;
  }

  /// Fallback hash generation when main method fails
  static String _generateFallbackHash(int length) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(10000);
    return _generateMd5('fallback-$timestamp-$rnd', length);
  }

  /// Generates an MD5 hash of specified length
  static String _generateMd5(String input, int length) {
    final hash = md5.convert(utf8.encode(input)).toString();
    return hash.substring(0, min(length, hash.length));
  }
}
```

For more information see: https://logging.apache.org/log4j/2.x/manual/thread-context.html

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
