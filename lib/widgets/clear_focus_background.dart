import 'package:flutter/material.dart';
import 'package:cinetime/utils/_utils.dart';

class ClearFocusBackground extends StatelessWidget {
  const ClearFocusBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.clearFocus(),
      child: child,
    );
  }
}
