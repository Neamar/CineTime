import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconMessage extends StatelessWidget {
  static const IconData iconSad = FontAwesomeIcons.frown;
  static const IconData iconError = FontAwesomeIcons.sadTear;

  final IconData icon;
  final String message;
  final String? tooltip;
  final bool inline;
  final bool redIcon;
  final Color? textColor;

  const IconMessage({Key? key, required this.icon, required this.message, this.tooltip, this.inline = false, this.redIcon = false, this.textColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      message,
      textAlign: TextAlign.center,
      style: textColor != null ? TextStyle(color: textColor) : null,
    );

    if (tooltip != null)
      text = Tooltip(
        child: text,
        message: tooltip!,
      );

    return Flex(
      direction: inline ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          icon,
          color: redIcon ? Theme.of(context).primaryColor : null,
          size: inline ? 25 : 50,
        ),
        AppResources.spacerLarge,
        Center(child: text),
      ],
    );
  }
}