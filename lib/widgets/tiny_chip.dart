import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

class TinyChip extends StatelessWidget {
  final String label;

  const TinyChip({super.key, required this.label});

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
          style: context.textTheme.bodySmall!.copyWith(fontSize: 6),
        ),
      )
    );
  }
}
