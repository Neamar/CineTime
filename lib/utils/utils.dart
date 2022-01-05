import 'dart:async';
import 'dart:io';
import 'package:cinetime/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '_utils.dart';
import 'exceptions/connectivity_exception.dart';
import 'exceptions/detailed_exception.dart';
import 'exceptions/displayable_exception.dart';
import 'exceptions/operation_canceled_exception.dart';
import 'exceptions/permission_exception.dart';
import 'exceptions/unreported_exception.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = Iterable<dynamic>;
typedef AsyncTask<R> = Future<R> Function();
typedef ParameterizedAsyncTask<T, R> = Future<R> Function(T? param);
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


/// Display an error to the user
Future<void> showError(BuildContext context, Object error) async {
  // Cancellation
  if (error is OperationCanceledException) {
    if (!error.silent) {
      showMessage(context, 'Opération annulée', isError: true);
    }
  }

  // Permission
  else if (error is PermissionDeniedException) {
    showMessage(context, 'Permission requise', isError: true);
  }

  // Bad connectivity
  else if (error is ConnectivityException) {
    showMessage(context, 'Vérifiez votre connexion internet', isError: true);
  }

  // Server error
  else if (error is HttpResponseException) {
    showMessage(context, 'Erreur serveur', exception: error);
  }

  // Displayable exception
  else if (error is DisplayableException) {
    showMessage(context, error.toString(), isError: true);
  }

  // Other
  else {
    showMessage(context, 'Une erreur est survenue', isError: true);
  }
}

/// Report error to Crashlytics
Future<void> reportError(Object exception, StackTrace stack, {dynamic reason}) async {
  if (!shouldReportException(exception)) return;

  if (exception is DetailedException)
    exception = exception.toStringVerbose();

  // Report to Sentry;
  Sentry.captureException(exception, stackTrace: stack, hint: reason);
}

/// Indicate whether this exception should be reported
bool shouldReportException(Object? exception) =>
    exception != null &&
    exception is! UnreportedException &&
    exception is! SocketException &&
    exception is! TimeoutException &&
    (exception is! HttpResponseException || exception.shouldBeReported);

bool isIterableNullOrEmpty<T>(Iterable<T>? iterable) => iterable == null || iterable.isEmpty;
bool isMapNullOrEmpty<K, V>(Map<K, V>? map) => map == null || map.isEmpty;
bool isStringNullOrEmpty(String? s) => s == null || s.isEmpty;

/// Returns true if T1 and T2 are identical types.
/// This will be false if one type is a derived type of the other.
bool typesEqual<T1, T2>() => T1 == T2;

/// Returns true if T is not set, Null, void or dynamic.
bool isTypeUndefined<T>() => typesEqual<T, Object?>() || typesEqual<T, Null>() || typesEqual<T, void>() || typesEqual<T, dynamic>();

/// Returns true if T is nullable.
/// Like [isTypeUndefined] but will also return true for nullable types like <bool?> or <Object?>.
bool isTypeNullable<T>() => null is T;

DateTime? dateFromString(String? dateString) => DateTime.tryParse(dateString ?? '');
String? dateToString(DateTime? date) => date?.toIso8601String();

/// Use this on [JsonKey.toJson] to ignore serialisation for this field
/// @JsonKey(toJson: toEmptyJsonValue)
String? toEmptyJsonValue<T>(T? value) => null;

String convertBasicHtmlTags(String htmlText) {
  // Replace all double line break with single line break
  htmlText = htmlText.replaceAll('<br><br>', '\n');

  // Replace all remaining line break
  htmlText = htmlText.replaceAll('<br>', '\n');

  // Replace all html spaces by space
  htmlText = htmlText.replaceAll('&nbsp;', ' ');

  // Remove other tags
  RegExp exp = RegExp(
    r'<[^>]*>',
    multiLine: true,
    caseSensitive: true,
  );

  return htmlText.replaceAll(exp, '');
}
