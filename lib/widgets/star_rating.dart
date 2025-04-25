import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating(this.rating, {super.key}) :
    assert(rating >= 0 && rating <= 5);

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < rating.floor(); i ++)
          _buildStar(true),
        if (rating % 1 != 0)
          _buildPartialStar(rating % 1),
        for (var i = rating.ceil(); i < 5; i ++)
          _buildStar(false),
      ],
    );
  }

  Widget _buildStar(bool solid) {
    return Icon(
      solid ? Icons.star : Icons.star_border,
      color: Colors.orange,
      size: 18,
    );
  }

  Widget _buildPartialStar(double fullness) {
    return Stack(
      children: [
        _buildStar(false),
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fullness,
            child: ClipRect(
              child: _buildStar(true),
            ),
          ),
        ),
      ],
    );
  }
}
