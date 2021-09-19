import 'package:flutter/material.dart';

import 'disposable.dart';

mixin BlocProvider<S extends StatefulWidget, T extends Disposable> on State<S> {
  late final T bloc;

  @override
  void initState() {
    super.initState();
    bloc = initBloc();
  }

  T initBloc();

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}
