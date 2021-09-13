import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:collection/collection.dart';

import 'utils.dart';

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

extension ExtendedDateTime on DateTime {
  /// Return a new DateTime of the day (with time part at 0)
  DateTime get date => DateTime(this.year, this.month, this.day);
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
}

extension ExtendedList<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= this.length)
      return null;
    return this.elementAt(index);
  }

  /// Insert [widget] between each member of this list
  void insertBetween(T item) {
    if (this.length > 1) {
      for (var i = this.length - 1; i > 0; i--) this.insert(i, item);
    }
  }

  /// Return true if this list's content is equals to [other]'s.
  bool isEqualTo(List<T>? other) {
    const comparator = ListEquality();
    return comparator.equals(this, other);
  }
}

extension ExtendedNum on num {
  bool isBetween(num min, num max) => this >= min && this <= max;

  bool get isPositive => !this.isNegative;
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