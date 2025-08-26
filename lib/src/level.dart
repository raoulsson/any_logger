// ////////////////////////////////////////////////
// When to use the different log levels?
// https://stackoverflow.com/q/2031163/132396
// ////////////////////////////////////////////////

enum Level {
  ALL(0),
  TRACE(100),
  DEBUG(200),
  INFO(300),
  WARN(400),
  ERROR(500),
  FATAL(600),
  OFF(700);

  final int value;

  const Level(this.value);

  bool operator <(Level other) => value < other.value;

  bool operator <=(Level other) => value <= other.value;

  bool operator >(Level other) => value > other.value;

  bool operator >=(Level other) => value >= other.value;

  static Level? fromString(String? s) {
    if (s == null) return null;

    final upperString = s.toUpperCase();
    try {
      return Level.values.firstWhere(
        (level) => level.name == upperString,
        orElse: () => throw FormatException('Unknown level: $s'),
      );
    } on FormatException {
      return null;
    }
  }

  String get displayName => name;

  @override
  String toString() => name;
}
