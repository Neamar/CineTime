import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

class TextWithLabel extends StatelessWidget {
  const TextWithLabel({
    super.key,
    required this.label,
    required this.text,
    this.singleLine = false,
  });

  final String label;
  final String text;
  final bool singleLine;

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
            maxLines: singleLine ? 1 : null,
            overflow: singleLine ? TextOverflow.ellipsis : null,
          ),
        )
      ],
    );
  }
}
