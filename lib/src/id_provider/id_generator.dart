import 'dart:math';

/// Simple ID generator without crypto dependency
class IdGenerator {
  static const int _ID_LENGTH = 8;

  // Bitcoin-like base58 character set (no 0, O, I, l to avoid confusion)
  static const String _BASE58_CHARS = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  // Alternative: Simple base32 (even easier to read)
  static const String _BASE32_CHARS = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // No 0, 1, I, O

  // Alternative: Lowercase alphanumeric (base36)
  static const String _BASE36_CHARS = '0123456789abcdefghijklmnopqrstuvwxyz';

  // Alternative: Hex (base16) - simplest
  static const String _HEX_CHARS = '0123456789abcdef';

  static final Random _random = Random.secure(); // Use secure random for better entropy

  /// Generates a random ID using base58 characters (Bitcoin-style)
  static String generateBase58Id([int length = _ID_LENGTH]) {
    return _generateRandomString(_BASE58_CHARS, length);
  }

  /// Generates a random ID using base32 characters (easier to read/type)
  static String generateBase32Id([int length = _ID_LENGTH]) {
    return _generateRandomString(_BASE32_CHARS, length);
  }

  /// Generates a random ID using base36 characters
  static String generateBase36Id([int length = _ID_LENGTH]) {
    return _generateRandomString(_BASE36_CHARS, length);
  }

  /// Generates a random ID using hex characters (simplest)
  static String generateHexId([int length = _ID_LENGTH]) {
    return _generateRandomString(_HEX_CHARS, length);
  }

  /// Generate a deterministic ID from input (for device ID that should be stable)
  /// Uses a simple hash-like algorithm without crypto
  static String generateDeterministicId(String input, [int length = _ID_LENGTH]) {
    // Simple hash function without crypto
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Keep it 32-bit
    }

    // Add some entropy from the input length and first/last chars
    if (input.isNotEmpty) {
      hash ^= input.length * 31;
      hash ^= input.codeUnitAt(0) << 16;
      hash ^= input.codeUnitAt(input.length - 1) << 8;
    }

    // Convert hash to base58 string
    final chars = _BASE58_CHARS;
    final buffer = StringBuffer();

    // Use the hash as seed for consistent output
    var value = hash.abs();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[value % chars.length]);
      value = (value ~/ chars.length) ^ (value * 31); // Mix for better distribution
    }

    return buffer.toString();
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
