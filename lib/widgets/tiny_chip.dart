import 'package:flutter/material.dart';

class TinyChip extends StatelessWidget {
  final String label;

  const TinyChip({Key key, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(),
        color: Colors.cyan
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(label),
      )
    );
  }
}
