import 'dart:convert';

import 'package:cinetime/models/date_time.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:diacritic/diacritic.dart';

import 'utils.dart';

extension ExtendedString on String {
  String decodeBase64() => utf8.decode(base64.decode(this));
  String toBase64() => base64.encode(utf8.encode(this));

  String plural(int count) => '$count ${this}${count > 1 ? 's' : ''}';

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

  /// Remove all whitespaces
  String removeAllWhitespaces() => replaceAll(RegExp(r'\s+'), '');
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

  /// Validate the enclosing [Form]
  void validateForm({VoidCallback? onSuccess}) {
    clearFocus();
    final form = Form.of(this);
    if (form == null) return;

    if (form.validate()) {
      form.save();
      onSuccess?.call();
    }
  }
}

extension ExtendedBehaviorSubject<T> on BehaviorSubject<T> {
  void tryAdd(T value) {
    if (!isClosed) {
      add(value);
    }
  }

  void addNotNull(T? value) {
    if (value != null) {
      add(value);
    }
  }

  /// Add [value] to subject only if it's different from the current value.
  /// Return true if [value] was added.
  bool addDistinct(T value) {
    if (value != this.value) {
      add(value);
      return true;
    }
    return false;
  }
}

extension ExtendedIterable<T> on Iterable<T> {
  T? elementAtOrDefault(int? index, [T? defaultReturn]) {
    if (index == null || index < 0 || index >= length) return defaultReturn;
    return elementAt(index);
  }

  /// The first element satisfying test, or null if there are none.
  /// Copied from Flutter.collection package
  /// https://api.flutter.dev/flutter/package-collection_collection/IterableExtension/firstWhereOrNull.html
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length)
      return null;
    return elementAt(index);
  }

  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }

  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index, item);
      index++;
    }
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

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length)
      return null;
    return elementAt(index);
  }

  /// Return true if this list's content is equals to [other]'s.
  bool isEqualTo(List<T>? other) {
    const comparator = ListEquality();
    return comparator.equals(this, other);
  }
}

extension ExtendedSet<T> on Set<T> {
  /// Return true if this set's content is equals to [other]'s.
  bool isEqualTo(Set<T>? other) {
    const comparator = SetEquality();
    return comparator.equals(this, other);
  }
}

extension ExtendedObjectIterable<Object> on Iterable<Object> {
  /// Converts each element to a String and concatenates the strings, ignoring null and empty values.
  String joinNotEmpty(String separator) => map((e) => e?.toString())
      .where((string) => !isStringNullOrEmpty(string))
      .join(separator);

  /// Returns a string separated by a newline character for each non-null element
  String toLines() => joinNotEmpty('\n');
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

  String toWeekdayString({bool withDay = false, bool withMonth = false}) {
    var formattedDate = AppResources.weekdayNamesShort[weekday]!;

    if (!withDay && !withMonth)
      return formattedDate;

    formattedDate += ' ' + day.toTwoDigitsString();

    if (!withMonth)
      return formattedDate;

    return formattedDate + ' ' + AppResources.formatterMonth.format(this);
  }
}