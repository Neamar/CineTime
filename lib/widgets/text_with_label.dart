import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';

class TextWithLabel extends StatelessWidget {
  final String label;
  final String text;

  const TextWithLabel({Key key, this.label, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.caption,
          ),
          AppResources.WidgetSpacerTiny,
          Flexible(
            child: Text(
              text,
            ),
          )
        ],
      ),
    );
  }
}
