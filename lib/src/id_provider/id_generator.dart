import 'dart:math';

/// Simple ID generator without crypto dependency
class IdGenerator {
  static const int _ID_LENGTH = 8;

  // Alternative: Lowercase alphanumeric (base36)
  static const String _BASE36_CHARS = '0123456789abcdefghijklmnopqrstuvwxyz';

  static final Random _random = Random.secure(); // Use secure random for better entropy

  /// Generates a random ID using base36 characters
  static String generateBase36Id([int length = _ID_LENGTH]) {
    return _generateRandomString(_BASE36_CHARS, length);
  }

  /// Core random string generator
  static String _generateRandomString(String charset, int length) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(charset[_random.nextInt(charset.length)]);
    }
    return buffer.toString();
  }
}
