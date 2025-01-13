import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

import 'themed_widgets.dart';

class ShowMoreText extends StatefulWidget {
  const ShowMoreText({super.key, this.header, required this.text, required this.collapsedHeight});

  final String? header;
  final String text;
  final double collapsedHeight;

  @override
  State<ShowMoreText> createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Build the text
        final textSpan = TextSpan(
          style: context.textTheme.bodyMedium,
          children: [
            if (widget.header != null)...[
              TextSpan(text: '${widget.header!}\n', style: const TextStyle(color: AppResources.colorDarkRed, fontWeight: FontWeight.w500)),
              const TextSpan(text: '\n', style: TextStyle(fontSize: 5)),
            ],
            TextSpan(text: widget.text),
          ],
        );

        // Layout the text to calculate its height
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.justify,
          maxLines: 100,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);
        final height = textPainter.size.height;

        // Build the text widget
        final text = RichText(
          text: textSpan,
          textAlign: TextAlign.justify,
          maxLines: 100,
          overflow: TextOverflow.ellipsis,
        );

        // If the text is smaller than the collapsed height, don't show the "Show more" button
        if (height <= widget.collapsedHeight) {
          return text;
        }

        return GestureDetector(
          child: CtAnimatedSwitcher(
            sizeAnimation: true,
            child: () {
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
      },
    );
  }
}