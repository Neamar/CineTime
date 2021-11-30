import 'package:flutter/material.dart';

class TinyChip extends StatelessWidget {
  final String label;

  const TinyChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        color: Colors.cyan
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.caption!.copyWith(fontSize: 6),
        ),
      )
    );
  }
}
