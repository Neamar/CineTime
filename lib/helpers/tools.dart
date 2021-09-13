import 'package:cinetime/models/date_time.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';

Future<T?> navigateTo<T extends Object>(BuildContext context, Widget Function() builder, {int? removePreviousRoutesAmount, bool clearHistory = false}) async {
  assert(!(clearHistory == true && removePreviousRoutesAmount != null));

  var route = MaterialPageRoute<T>(
    builder: (context) => builder()
  );

  if (clearHistory != true && removePreviousRoutesAmount == null) {
    return await Navigator.of(context).push(route);
  } else {
    int removedCount = 0;
    return await Navigator.of(context).pushAndRemoveUntil(route,
      (r) => clearHistory != true &&
      (removePreviousRoutesAmount != null && removedCount++ >= removePreviousRoutesAmount)
    );
  }
}

String plural(int count, String input) => '$count $input${count > 1 ? 's' : ''}';

bool isIterableNullOrEmpty<T>(Iterable<T>? iterable) => iterable == null || iterable.isEmpty;
bool isMapNullOrEmpty<K, V>(Map<K, V>? map) => map == null || map.isEmpty;
bool isStringNullOrEmpty(String? s) => s == null || s.isEmpty;

DateTime? dateFromString(String? date) {
  if (date?.isNotEmpty != true)
    return null;

  return DateTime.tryParse(date!);
}

String? removeAllHtmlTags(String? htmlText) {
  if (htmlText == null)
    return null;

  RegExp exp = RegExp(
      r"<[^>]*>",
      multiLine: true,
      caseSensitive: true
  );

  return htmlText.replaceAll(exp, '');
}

extension ExtendedMap<K, V> on Map<K, V> {
  V? elementAt(K key) => this[key];
}

extension ExtendedWidgetList on List<Widget> {
  /// Insert [widget] between each member of this list
  List<Widget> insertBetween(Widget widget) {
    if (this.length > 1) {
      for (var i = this.length - 1; i > 0 ; i--)
        this.insert(i, widget);
    }

    return this;
  }
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

  String? toWeekdayString({bool? withDay, bool? withMonth}) {
    var formattedDate = AppResources.weekdayNames[this.weekday]!;

    if (withDay != true && withMonth != true)
      return formattedDate;

    formattedDate += ' ' + this.day.toTwoDigitsString();

    if (withMonth != true)
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

extension ExtendedString on String {
  /// Returns a new string in which the last occurrence of [from] in this string is replaced with [to]
  String replaceLast(Pattern from, String to) {
    var startIndex = this.lastIndexOf(from);
    return this.replaceFirst(from, to, startIndex != -1 ? startIndex : 0);
  }
}

extension ExtendedNum on num {
  /// Copied from DateTime._twoDigits()
  /// This is lighter than NumberFormat("00") and avoid depending on a package
  String toTwoDigitsString() {
    if (this >= 10) return "$this";
    return "0$this";
  }
}

extension ExtendedSet<T> on Set<T> {
  /// Returns whether this Set contains the same elements of [other].
  bool containsSame(Iterable<T>? other) {
    if (other == null || this.length != other.length)
      return false;

    return this.containsAll(other);
  }
}