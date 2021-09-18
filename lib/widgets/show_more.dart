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
            return ShaderMask(
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

/** TODO remove ?
/// Copied from flutter_show_more 0.1.2
/// - set onTap behaviour on all text
/// - add AnimatedSize
class ShowMoreText extends StatefulWidget {
  final String text;
  final int maxLength;
  final String showMoreText;
  final TextStyle style;
  final TextStyle showMoreStyle;
  final bool shouldShowLessText;
  final String showLessText;

  const ShowMoreText(
      this.text, {
        Key key,
        this.maxLength: 100,
        this.showMoreText,
        this.style,
        this.showMoreStyle,
        this.shouldShowLessText: false,
        this.showLessText,
      })  : assert(text != null),
        assert(maxLength != null),
        assert(shouldShowLessText != null),
        super(key: key);

  @override
  _ShowMoreTextState createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> with SingleTickerProviderStateMixin {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.length <= widget.maxLength) {
      return Text(widget.text, style: widget.style);
    }

    var showMoreStyle = widget.showMoreStyle ??
        Theme.of(context).textTheme.body2.copyWith(
          color: Theme.of(context).accentColor,
        );

    Widget child;

    if (isExpanded) {
      if (widget.shouldShowLessText) {
        child = Text.rich(
          TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: widget.text),
              TextSpan(text: ' '),
              TextSpan(
                text: widget.showMoreText ?? 'less',
                style: showMoreStyle,
              ),
            ],
          ),
        );
      } else {
        child = Text(widget.text, style: widget.style);
      }
    } else {
      var substring = widget.text.substring(0, widget.maxLength);

      child = Text.rich(
        TextSpan(
          style: widget.style,
          children: [
            TextSpan(text: substring),
            TextSpan(text: '... '),
            TextSpan(
              text: widget.showMoreText ?? 'more',
              style: showMoreStyle,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      child: AnimatedSize(
        duration: Duration(milliseconds: 250),
        alignment: Alignment.topLeft,
        child: child,
        vsync: this,
      ),
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
    );
  }
}
*/