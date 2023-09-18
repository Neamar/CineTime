import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

import 'themed_widgets.dart';

class ShowMoreText extends StatefulWidget {
  const ShowMoreText({Key? key, this.header, required this.text, required this.collapsedHeight}) : super(key: key);

  final String? header;
  final String text;
  final double collapsedHeight;

  @override
  _ShowMoreTextState createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CtAnimatedSwitcher(
        sizeAnimation: true,
        child: () {
          final text = RichText(
            text: TextSpan(
              style: context.textTheme.bodyText2,
              children: [
                if (widget.header != null)...[
                  TextSpan(text: widget.header! + '\n', style: const TextStyle(color: AppResources.colorDarkRed, fontWeight: FontWeight.w500)),
                  WidgetSpan(child: SizedBox(height: AppResources.spacerTiny.height, width: double.infinity)),
                ],
                TextSpan(text: widget.text),
              ],
            ),
            textAlign: TextAlign.justify,
            maxLines: 100,
            overflow: TextOverflow.ellipsis,
          );

          if (isExpanded) {
            return text;
          } else {
            return ShaderMask(    // Draw a gradient overlay would probably be more performant, but ShaderMask works on all backgrounds.
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: widget.collapsedHeight,
                child: text,
              ),
            );
          }
        } (),
      ),
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
    );
  }
}