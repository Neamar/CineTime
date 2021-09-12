import 'package:flutter/painting.dart';

class CornerBorder extends ShapeBorder {
  const CornerBorder();

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) => _getCornerPath(rect);

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) => _getCornerPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    // Paint nothing
  }

  Path _getCornerPath(Rect rect) {
    //TODO use Path().addPolygon() instead ?
    return Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.height)
      ..lineTo(rect.left, rect.top)
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => CornerBorder();
}