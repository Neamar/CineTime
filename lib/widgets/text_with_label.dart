import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';
import 'package:marquee_widget/marquee_widget.dart';

class TextWithLabel extends StatelessWidget {
  final String label;
  final String text;

  const TextWithLabel({Key key, this.label, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
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

    return IntrinsicWidth(
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.caption,
          ),
          AppResources.WidgetSpacerTiny,
          Flexible(
            child: Marquee(   //TODO develop component from scratch with : overflow.fade, instead of going backward : cross-fade and start from beginning, skip if text fits
              child: Text(
                text,
              ),
            ),
          )
        ],
      ),
    );
  }
}
