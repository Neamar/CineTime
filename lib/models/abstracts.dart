import 'package:flutter/material.dart';
import 'package:cinetime/utils/_utils.dart';

mixin Disposable {
  bool isDisposed = false;

  @mustCallSuper
  void dispose() {
    isDisposed = true;
  }
}

abstract class Identifiable {
  const Identifiable.fromId(this.id);

  /// Base64 encoded [code]
  /// Decoded examples : 'Movie:133392', 'Theater:C0026', 'Video:brand.video_legacy.AC.19589606'
  final String id;

  /// API codes may be int or string.
  /// Examples : 133392 (movie), 'P0671' (theater)
  String get code => _codeFromId(id);

  /// Convert id to code
  static String _codeFromId(String id) {
    final decoded = id.decodeBase64();
    return decoded.substring(decoded.indexOf(':') + 1);
  }

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