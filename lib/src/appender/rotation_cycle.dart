/// Enhanced rotation cycle with sub-day intervals
enum RotationCycle {
  NEVER('never', null),
  TEN_MINUTES('10min', Duration(minutes: 10)),
  THIRTY_MINUTES('30min', Duration(minutes: 30)),
  HOURLY('hour', Duration(hours: 1)),
  TWO_HOURS('2hour', Duration(hours: 2)),
  THREE_HOURS('3hour', Duration(hours: 3)),
  FOUR_HOURS('4hour', Duration(hours: 4)),
  SIX_HOURS('6hour', Duration(hours: 6)),
  TWELVE_HOURS('12hour', Duration(hours: 12)),
  DAILY('day', Duration(days: 1)),
  WEEKLY('week', Duration(days: 7)),
  MONTHLY('month', null); // Special handling needed

  final String value;
  final Duration? duration;

  const RotationCycle(this.value, this.duration);

  static RotationCycle fromString(String? value) {
    if (value == null || value.isEmpty) {
      throw ArgumentError('RotationCycle value cannot be null or empty');
    }

    final normalizedValue = value.toLowerCase().trim();

    // Try exact value match first
    try {
      return RotationCycle.values.firstWhere(
        (cycle) => cycle.value == normalizedValue,
      );
    } catch (_) {
      // Not found by exact value, try alternatives
    }

    // Try by enum name
    try {
      return RotationCycle.values.firstWhere(
        (cycle) => cycle.name.toLowerCase() == normalizedValue,
      );
    } catch (_) {
      // Not found by name, try aliases
    }

    // Handle common aliases and variations
    switch (normalizedValue) {
      // Never aliases
      case 'none':
      case 'off':
      case 'disabled':
        return NEVER;

      // 10 minutes aliases
      case '10m':
      case '10mins':
      case '10minutes':
      case '10_minutes':
      case 'ten_minutes':
        return TEN_MINUTES;

      // 30 minutes aliases
      case '30m':
      case '30mins':
      case '30minutes':
      case '30_minutes':
      case 'thirty_minutes':
      case 'halfhour':
      case 'half_hour':
        return THIRTY_MINUTES;

      // Hourly aliases
      case '1h':
      case '1hour':
      case '60min':
      case '60mins':
      case 'hourly':
      case 'every_hour':
        return HOURLY;

      // 2 hours aliases
      case '2h':
      case '2hrs':
      case '2hours':
      case '2_hours':
      case 'two_hours':
      case '120min':
        return TWO_HOURS;

      // 3 hours aliases
      case '3h':
      case '3hrs':
      case '3hours':
      case '3_hours':
      case 'three_hours':
        return THREE_HOURS;

      // 4 hours aliases
      case '4h':
      case '4hrs':
      case '4hours':
      case '4_hours':
      case 'four_hours':
        return FOUR_HOURS;

      // 6 hours aliases
      case '6h':
      case '6hrs':
      case '6hours':
      case '6_hours':
      case 'six_hours':
        return SIX_HOURS;

      // 12 hours aliases
      case '12h':
      case '12hrs':
      case '12hours':
      case '12_hours':
      case 'twelve_hours':
      case 'halfday':
      case 'half_day':
        return TWELVE_HOURS;

      // Daily aliases
      case '1d':
      case '1day':
      case '24h':
      case '24hours':
      case 'daily':
      case 'every_day':
        return DAILY;

      // Weekly aliases
      case '1w':
      case '7d':
      case '7days':
      case 'weekly':
      case 'every_week':
        return WEEKLY;

      // Monthly aliases
      case '1m':
      case '30d':
      case '30days':
      case 'monthly':
      case 'every_month':
        return MONTHLY;

      default:
        // Fail fast with descriptive error
        throw ArgumentError('Unknown RotationCycle value: "$value". '
            'Valid values are: ${RotationCycle.values.map((e) => e.value).join(", ")} '
            'or enum names: ${RotationCycle.values.map((e) => e.name).join(", ")}');
    }
  }

  /// Safe parsing that returns null instead of throwing
  static RotationCycle? tryFromString(String? value) {
    try {
      return fromString(value);
    } catch (_) {
      return null;
    }
  }

  /// Check if rotation is needed based on last rotation time
  bool shouldRotate(DateTime lastRotation) {
    if (this == NEVER) return false;

    final now = DateTime.now();

    switch (this) {
      case MONTHLY:
        // Rotate on month change
        return now.year > lastRotation.year || now.month > lastRotation.month;
      case WEEKLY:
        // Use calendar week calculation
        return _getCalendarWeek(now) != _getCalendarWeek(lastRotation) ||
            now.year > lastRotation.year;
      case DAILY:
        // Rotate on day change
        return now.day != lastRotation.day ||
            now.month != lastRotation.month ||
            now.year != lastRotation.year;
      default:
        // For all time-based rotations
        if (duration != null) {
          return now.difference(lastRotation) >= duration!;
        }
        return false;
    }
  }

  /// Get filename suffix based on rotation cycle and timestamp
  String getFilenameSuffix(DateTime timestamp) {
    switch (this) {
      case NEVER:
        return '';
      case MONTHLY:
        return '_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      case WEEKLY:
        return '_${timestamp.year}-CW${_getCalendarWeek(timestamp)}';
      case DAILY:
        return '_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      default:
        // For hourly/sub-daily rotations, include time
        return '_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}'
            '_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  static int _getCalendarWeek(DateTime date) {
    // ISO 8601 week calculation
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday == 1
        ? startOfYear
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));

    if (date.isBefore(firstMonday)) {
      // Date is in the last week of previous year
      return _getCalendarWeek(DateTime(date.year - 1, 12, 31));
    }

    final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }
}
