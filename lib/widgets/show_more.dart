import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

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
          textScaler: MediaQuery.textScalerOf(context),   // Adapt to OS text scale
        )..layout(maxWidth: constraints.maxWidth);
        final height = textPainter.size.height;

        // Build the text widget
        final text = RichText(
          text: textSpan,
          textAlign: TextAlign.justify,
          maxLines: 100,
          overflow: TextOverflow.ellipsis,
          textScaler: MediaQuery.textScalerOf(context),   // Same as the painter, so the measured height matches
        );

        // If the text is smaller than the collapsed height, don't show the "Show more" button
        if (height <= widget.collapsedHeight) {
          return text;
        }

        return GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: isExpanded ? 1 : 0),
            duration: AppResources.durationAnimationMedium,
            curve: Curves.easeInOut,
            // Draw a gradient overlay would probably be more performant, but ShaderMask works on all backgrounds.
            // It's outside the ClipRect so the gradient follows the animated height.
            builder: (context, expansion, child) {
              // The text always keeps its full height, only the visible window animates (otherwise the text would be clipped instantly when collapsing)
              final collapsedFactor = widget.collapsedHeight / height;
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black.withValues(alpha: expansion)],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    heightFactor: collapsedFactor + (1 - collapsedFactor) * expansion,
                    child: child,
                  ),
                ),
              );
            },
            child: text,
          ),
        );
      },
    );
  }
}