import 'dart:convert';

import 'package:cinetime/models/date_time.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';

import 'utils.dart';

extension ExtendedString on String {
  String decodeBase64() => utf8.decode(base64.decode(this));
  String toBase64() => base64.encode(utf8.encode(this));

  String plural(int count) => '$count $this${count > 1 ? 's' : ''}';

  /// Return the string with first character converted to capital (uppercase) letter
  String get capitalized {
    if (isEmpty) return '';
    if (length == 1) return toUpperCase();
    return this[0].toUpperCase() + substring(1);
  }

  /// Normalize a string by removing diacritics and transform to lower case
  String get normalized => removeDiacritics(toLowerCase());

  /// Returns a new string in which the last occurrence of [from] in this string is replaced with [to]
  String replaceLast(Pattern from, String to) {
    var startIndex = lastIndexOf(from);
    return replaceFirst(from, to, startIndex != -1 ? startIndex : 0);
  }

  /// Remove all whitespaces characters
  String removeAllWhitespaces() => replaceAll(RegExp(r'\s+'), '');

  /// Remove all new lines characters
  String removeAllNewLines() => replaceAll(RegExp(r'\n+'), '');
}

extension ExtendedNullableString on String? {
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension ExtendedNum on num {
  bool isBetween(num min, num max) => this >= min && this <= max;

  bool get isPositive => !isNegative;

  /// Copied from DateTime._twoDigits()
  /// This is lighter than NumberFormat("00") and avoid depending on a package
  String toTwoDigitsString() {
    if (this >= 10) return '$this';
    return '0$this';
  }
}

extension ExtendedBuildContext on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get canPop => ModalRoute.of(this)?.canPop == true;

  /// Clear current context focus.
  /// This is the cleanest, official way.
  void clearFocus() => FocusScope.of(this).unfocus();

  /// Clear current context focus (Second method)
  /// Use this method if [clearFocus] doesn't work.
  void clearFocus2() => FocusScope.of(this).requestFocus(FocusNode());
}

extension ExtendedIterable<T> on Iterable<T> {
  /// Get element at [index], and return null if not in range.
  /// [index] can be negative (whereas the collection package's one throws).
  T? elementAtOrNull(int? index) {
    if (index == null || index < 0 || index >= length) return null;
    return elementAt(index);
  }
}

extension ExtendedList<T> on List<T> {
  void addNotNull(T? value) {
    if (value != null) {
      add(value);
    }
  }

  /// Insert [widget] between each member of this list
  void insertBetween(T item) {
    if (length > 1) {
      for (var i = length - 1; i > 0; i--) insert(i, item);
    }
  }

  /// Return true if this list's content is equals to [other]'s.
  bool isEqualTo(List<T>? other) {
    const comparator = ListEquality();
    return comparator.equals(this, other);
  }
}

extension ExtendedSet<T> on Set<T> {
  /// Return true if this set's content is equals to [other]'s.
  bool isEqualTo(Set<T>? other) => const SetEquality().equals(this, other);
}

extension ExtendedComparableIterable<T extends Comparable<T>> on Iterable<T> {
  /// Compare this iterable with [other] element-wise, order independent (elements are sorted first).
  /// Useful to make a [Comparable.compareTo] consistent with `==` on a [Set]/unordered collection field,
  /// so equal-length-but-different-content collections don't wrongly compare as equal (e.g. in a [SplayTreeSet]).
  int compareUnordered(Iterable<T> other) {
    final sortedThis = toList()..sort();
    final sortedOther = other.toList()..sort();
    for (var i = 0; i < sortedThis.length && i < sortedOther.length; i++) {
      final comparison = sortedThis[i].compareTo(sortedOther[i]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

extension ExtendedObjectIterable<Object> on Iterable<Object> {
  /// Converts each element to a String and concatenates the strings, ignoring null and empty values.
  /// Returns null if there is nothing left to join, rather than an empty string.
  String? joinNotEmpty(String separator) {
    final strings = map((e) => e?.toString()).where((string) => !isStringNullOrEmpty(string));
    return strings.isEmpty ? null : strings.join(separator);
  }
}

extension ExtendedTimeOfDay on TimeOfDay {
  String toHourMinuteString() => '$hour:${minute.toTwoDigitsString()}';
}

extension ExtendedDateTime on DateTime {
  Date getNextWeekdayDate(int weekday) {
    var current = this;
    while ((current = current.add(const Duration(days: 1))).weekday != weekday)
      continue;
    return current.toDate;
  }

  DateTime getNextWednesday() => getNextWeekdayDate(DateTime.wednesday);

  /// Adds a number of days to the date.
  DateTime addDays(int days) => DateTime(year, month, day + days);

  /// Return a Date (without the time part)
  Date get toDate => Date(year, month, day);

  /// Return a Time (without the date part)
  Time get toTime => Time(hour, minute);

  bool isAfterOrSame(DateTime other) => this == other || isAfter(other);

  bool isAtSameDayAs(DateTime other) => year == other.year && month == other.month && day == other.day;

  String toWeekdayString({bool withDay = false, bool withMonth = false}) {
    var formattedDate = AppResources.weekdayNamesShort[weekday]!;

    if (!withDay && !withMonth)
      return formattedDate;

    formattedDate += ' ${day.toTwoDigitsString()}';

    if (!withMonth)
      return formattedDate;

    return '$formattedDate ${AppResources.formatterMonth.format(this)}';
  }
}

extension ExtendedColor on Color {
  Color get foregroundTextColor => computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
