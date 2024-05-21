import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class BehaviorSubjectBuilder<T> extends StreamBuilder<T> {
  BehaviorSubjectBuilder({ super.key, required BehaviorSubject<T> subject, required super.builder }) : super(
    stream: subject,
    initialData: subject.value,
  );
}