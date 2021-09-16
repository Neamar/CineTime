import 'package:flutter/painting.dart';

enum CornerBorderPosition { topRight, bottomRight }

class CornerBorder extends ShapeBorder {
  const CornerBorder(this.position);

  final CornerBorderPosition position;

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) => _getCornerPath(rect);

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) => _getCornerPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    // Paint nothing
  }

  Path _getCornerPath(Rect rect) {
    if (position == CornerBorderPosition.topRight) {
      return Path()
        ..moveTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.height)
        ..lineTo(rect.left, rect.top)
        ..close();
    } else if (position == CornerBorderPosition.bottomRight) {
      return Path()
        ..moveTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.right, rect.top)
        ..close();
    }
    throw UnimplementedError();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;
}