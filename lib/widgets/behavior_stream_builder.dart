import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';

class BehaviorStreamBuilder<T> extends StreamBuilder<T> {
  BehaviorStreamBuilder({ Key? key, required BehaviorSubject<T> subject, required AsyncWidgetBuilder<T> builder }) : super(
    key: key,
    stream: subject,
    initialData: subject.valueOrNull,
    builder: builder,
  );
}