import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';

class ShowMoreText extends StatefulWidget {
  final String text;
  final int collapsedMaxLines;

  ShowMoreText({Key? key, required this.text, this.collapsedMaxLines = 3}) : super(key: key);

  @override
  _ShowMoreTextState createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AnimatedSwitcher(
        duration: AppResources.durationAnimationMedium,
        layoutBuilder: _animatedSwitcherLayoutBuilder,
        child: () {
          final text =  Text(
            widget.text,
            textAlign: TextAlign.justify,
            maxLines: isExpanded ? 100 : widget.collapsedMaxLines,
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
              child: text,
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

  /// Copied from AnimatedSwitcher.defaultLayoutBuilder
  static Widget _animatedSwitcherLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
      alignment: Alignment.topLeft,
    );
  }
}