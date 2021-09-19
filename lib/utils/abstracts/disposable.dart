import 'package:flutter/foundation.dart';

mixin Disposable {
  bool isDisposed = false;

  @mustCallSuper
  void dispose() {
    isDisposed = true;
  }
}
