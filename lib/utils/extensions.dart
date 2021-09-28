import 'dart:convert';

import 'package:cinetime/models/date_time.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:collection/collection.dart';

import 'utils.dart';

extension ExtendedString on String {
  String decodeBase64() => utf8.decode(base64.decode(this));
  String toBase64() => base64.encode(utf8.encode(this));

  String plural(int count) => '$count ${this}${count > 1 ? 's' : ''}';

  /// Returns a new string in which the last occurrence of [from] in this string is replaced with [to]
  String replaceLast(Pattern from, String to) {
    var startIndex = this.lastIndexOf(from);
    return this.replaceFirst(from, to, startIndex != -1 ? startIndex : 0);
  }
}

extension ExtendedNum on num {
  bool isBetween(num min, num max) => this >= min && this <= max;

  bool get isPositive => !this.isNegative;

  /// Copied from DateTime._twoDigits()
  /// This is lighter than NumberFormat("00") and avoid depending on a package
  String toTwoDigitsString() {
    if (this >= 10) return "$this";
    return "0$this";
  }
}

extension ExtendedMap<K, V> on Map<K, V> {
  // Allow to use nullable syntax : map?.elementAt('key')
  V? elementAt(K key) => this[key];
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
  Future<void> validateForm({VoidCallback? onSuccess}) async {
    this.clearFocus();
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
    if (!this.isClosed) {
      this.add(value);
    }
  }

  void addNotNull(T? value) {
    if (value != null) {
      this.add(value);
    }
  }

  /// Add [value] to subject only if it's different from the current value.
  /// Return true if [value] was added.
  bool addDistinct(T value) {
    if (value != this.value) {
      this.add(value);
      return true;
    }
    return false;
  }

  /// Add current [value] to subject;
  void reAdd() => add(value);
}

extension ExtendedIterable<T> on Iterable<T> {
  T? elementAtOrDefault(int? index, [T? defaultReturn]) {
    if (index == null || index < 0 || index >= this.length) return defaultReturn;
    return this.elementAt(index);
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
    if (index < 0 || index >= this.length)
      return null;
    return this.elementAt(index);
  }

  T? get firstOrNull {
    if (this.isEmpty) return null;
    return this.first;
  }

  Iterable<E> mapIndexed<E>(E f(int index, T item)) sync* {
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
      this.add(value);
    }
  }

  /// Insert [widget] between each member of this list
  void insertBetween(T item) {
    if (this.length > 1) {
      for (var i = this.length - 1; i > 0; i--) this.insert(i, item);
    }
  }

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= this.length)
      return null;
    return this.elementAt(index);
  }

  /// Return true if this list's content is equals to [other]'s.
  bool isEqualTo(List<T>? other) {
    const comparator = ListEquality();
    return comparator.equals(this, other);
  }
}

extension ExtendedObjectIterable<Object> on Iterable<Object> {
  /// Converts each element to a String and concatenates the strings, ignoring null values.
  String joinNotNull(String separator) => this
      .map((e) => e?.toString())
      .where((string) => !isStringNullOrEmpty(string))
      .join(separator);

  /// Returns a string separated by a newline character for each non-null element
  String toLines() => this.joinNotNull('\n');
}

extension ExtendedDateTime on DateTime {
  Date getNextWeekdayDate(int weekday) {
    var current = this;
    while ((current = current.add(Duration(days: 1))).weekday != weekday)
      continue;
    return current.toDate;
  }

  DateTime getNextWednesday() => this.getNextWeekdayDate(DateTime.wednesday);

  /// Return a Date (without the time part)
  Date get toDate => Date(this.year, this.month, this.day);

  /// Return a Time (without the date part)
  Time get toTime => Time(this.hour, this.minute);

  String toWeekdayString({bool withDay = false, bool withMonth = false}) {
    var formattedDate = AppResources.weekdayNamesShort[this.weekday]!;

    if (!withDay && !withMonth)
      return formattedDate;

    formattedDate += ' ' + this.day.toTwoDigitsString();

    if (!withMonth)
      return formattedDate;

    return formattedDate + ' ' + AppResources.formatterMonth.format(this);
  }
}

extension ExtendedDateTimeIterable on Iterable<DateTime> {
  /// Return a formatted string like :
  /// - 'Tous les jours'              (if dates are each days until next tuesday)
  /// - 'jeu., ven. et dim.'          (if dates are before or is next tuesday)
  /// - 'ven. 28, sam. 29, mar. 1 avril et lun. 2 mai'  (if dates are after next tuesday. Add month if not current one)
  String toShortWeekdaysString(DateTime from) {
    // Get all dates after [from], remove duplicates, and sort.
    var weekdays = this
        .map((dateTime) => dateTime.toDate)
        .toSet()   //OPTI remove toSet and .sort from this method, supposing it's done before ?
        .toList(growable: false)
      ..sort();   //OPTI already sorted ?
    var nextWednesday = from.getNextWednesday();

    // If dates are each days until next tuesday
    if (nextWednesday.difference(from).inDays == weekdays.length)
      return 'Tous les jours';

    // Define function to format date
    var formatDate = (DateTime date) {
      if (date.isBefore(nextWednesday))
        return date.toWeekdayString();

      return date.toWeekdayString(withDay: true, withMonth: date.month != from.month);
    };

    // Fill a list of formatted weekday string
    final weekdaysString = <String?>[];
    for (var weekday in weekdays) {
      // Add formatted string to list
      weekdaysString.add(formatDate(weekday));
    }

    // Return formatted line
    return weekdaysString.join(' ');
  }

  /// Supposing [this] is sorted, return true if all dates have consecutive days.
  bool areAllConsecutiveDay() {
    if (this.length <= 1)
      return false;

    for (var i = 1; i < this.length; i++) {
      if (this.elementAt(i).toDate.difference(this.elementAt(i - 1).toDate).inDays != 1)
        return false;
    }

    return true;
  }
}