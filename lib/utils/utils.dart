import 'dart:async';
import 'package:flutter/material.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = Iterable<dynamic>;
typedef AsyncTask<T> = Future<T> Function();
typedef AsyncValueChanged<T> = Future<void> Function(T value);
typedef SubtreeBuilder = Widget Function(BuildContext context, Widget child);
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data);

/// Navigate to a new page.
/// Push a new page built with [builder] on the navigation stack.
///
/// if [returnAfterPageTransition] is true, the Future will return as soon as the page transition (animation) is over.
/// This is useful when you need an animation to keep running while the push transition is running, but to stop after the transition is over
/// (so that the animation is stopped during pop transition).
/// If null, will be set to true if [T] is not set.
///
/// if [animate] is false, the transition animation will be skipped.
Future<T?> navigateTo<T>(BuildContext context, WidgetBuilder builder, {
    bool removePreviousRoutesButFirst = false,
    int? removePreviousRoutesAmount,
    bool clearHistory = false,
    bool? returnAfterPageTransition,
    bool animate = true,
  }) async {
  // Check arguments
  if ([removePreviousRoutesButFirst, removePreviousRoutesAmount, clearHistory]
          .where((a) => (a is bool ? a == true : a != null))
          .length > 1) {
    throw ArgumentError('only one of removePreviousRoutesUntilNamed, removePreviousRoutesButFirst, removePreviousRoutesAmount and clearHistory parameters can be set');
  }

  // Build route
  final route = MaterialPageRoute<T>(
    builder: builder,
  );

  // Navigate
  Future<T?> navigationFuture;
  if (removePreviousRoutesButFirst != true &&
      removePreviousRoutesAmount == null &&
      clearHistory != true) {
    navigationFuture = Navigator.of(context).push(route);
  } else {
    int removedCount = 0;
    navigationFuture = Navigator.of(context).pushAndRemoveUntil(
      route,
      (r) =>
          (removePreviousRoutesButFirst != true || r.isFirst) &&
          (removePreviousRoutesAmount == null || removedCount++ >= removePreviousRoutesAmount) &&
          clearHistory != true,
    );
  }

  // Await
  returnAfterPageTransition ??= isTypeUndefined<T>();
  if (returnAfterPageTransition) {
    return await navigationFuture.timeout(route.transitionDuration * 2, onTimeout: () => null);
  } else {
    return await navigationFuture;
  }
}

void popToRoot(BuildContext context) => Navigator.of(context).popUntil((route) => route.isFirst);

bool isIterableNullOrEmpty<T>(Iterable<T>? iterable) => iterable == null || iterable.isEmpty;
bool isMapNullOrEmpty<K, V>(Map<K, V>? map) => map == null || map.isEmpty;
bool isStringNullOrEmpty(String? s) => s == null || s.isEmpty;

/// Returns true if T1 and T2 are identical types.
/// This will be false if one type is a derived type of the other.
bool typesEqual<T1, T2>() => T1 == T2;

/// Returns true if T is not set, Null, void or dynamic.
bool isTypeUndefined<T>() => typesEqual<T, Null>() || typesEqual<T, void>() || typesEqual<T, dynamic>();

/// Returns true if T is nullable.
/// Like [isTypeUndefined] but will also return true for nullable types like <bool?> or <Object?>.
bool isTypeNullable<T>() => null is T;

DateTime? dateFromString(String? dateString) => DateTime.tryParse(dateString ?? '');
String? dateToString(DateTime? date) => date?.toIso8601String();

/// Use this on [JsonKey.toJson] to ignore serialisation for this field
/// @JsonKey(toJson: toEmptyJsonValue)
String? toEmptyJsonValue<T>(T? value) => null;

String? convertBasicHtmlTags(String? htmlText) {
  if (htmlText == null)
    return null;

  htmlText = htmlText.replaceAll('<br>', '\n');

  RegExp exp = RegExp(
    r"<[^>]*>",
    multiLine: true,
    caseSensitive: true,
  );

  return htmlText.replaceAll(exp, '');
}
