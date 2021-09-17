import 'package:flutter/material.dart';

mixin Disposable {
  bool isDisposed = false;

  @mustCallSuper
  void dispose() {
    isDisposed = true;
  }
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