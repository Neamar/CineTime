import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

class TextWithLabel extends StatelessWidget {
  final String label;
  final String text;

  const TextWithLabel({super.key, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.ideographic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: <Widget>[
        Text(
          label,
          style: context.textTheme.bodySmall,
        ),
        AppResources.spacerTiny,
        Flexible(
          child: Text(
            text,
          ),
        )
      ],
    );
  }
}
