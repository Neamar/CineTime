import 'package:flutter/material.dart';

mixin Disposable {
  bool isDisposed = false;

  @mustCallSuper
  void dispose() {
    isDisposed = true;
  }
}

abstract class Identifiable {
  // TODO replace by 'id' : use base64 encoded ids. + Add method 'code' that decode it ?
  final String code;      // API codes are often int, but sometimes are String (for instance, for a theater : "P0671")

  const Identifiable(this.code);

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is Identifiable &&
      runtimeType == other.runtimeType &&
      code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class ExceptionWithMessage implements Exception {
  //Friendly message
  final String message;

  //Technical details
  final String? details;

  ExceptionWithMessage(this.message, {this.details});

  @override
  String toString() => message;
}