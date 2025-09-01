import 'appender/rotation_cycle.dart';

class Utils {
  static int getCalendarWeek(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday == 1
        ? startOfYear
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));

    if (date.isBefore(firstMonday)) {
      return getCalendarWeek(DateTime(date.year - 1, 12, 31));
    }

    final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }

  // This method seems unnecessary since RotationCycle.fromString() already exists
  static RotationCycle getRotationCycleFromString(String? s) {
    return RotationCycle.fromString(s);
  }
}
