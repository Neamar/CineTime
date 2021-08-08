import 'package:cinetime/helpers/tools.dart';

class Date extends DateTime {
  static final _unsupportedError = UnsupportedError("Date class only support date-related fields (without time)");

  Date(int year, int month, int day) : super(year, month, day);

  @override
  int get hour => throw _unsupportedError;

  @override
  int get minute => throw _unsupportedError;

  @override
  int get second => throw _unsupportedError;

  @override
  int get millisecond => throw _unsupportedError;

  @override
  int get microsecond => throw _unsupportedError;

  @override
  String toString() => '${day.toTwoDigitsString()}-${month.toTwoDigitsString()}-$year';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is Date &&
      runtimeType == other.runtimeType &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}

class Time implements Comparable<Time> {
  final int hour;
  final int minute;

  const Time(this.hour, this.minute);

  Time.fromDateTime(DateTime dateTime) :
    hour = dateTime.hour,
    minute = dateTime.minute;

  bool hasSameTime(DateTime dateTime) => hour == dateTime.hour && minute == dateTime.minute;

  @override
  int compareTo(Time other) {
    if (hour < other.hour)
      return -1;
    if (hour > other.hour)
      return 1;
    if (minute < other.minute)
      return -1;
    if (minute > other.minute)
      return 1;
    return 0;
  }

  @override
  String toString() => '$hour:${minute.toTwoDigitsString()}';     //'h' Version : => '${hour}h${minute > 0 ? minute.toTwoDigitsString() : ''}';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is Time &&
      runtimeType == other.runtimeType &&
      hour == other.hour &&
      minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}