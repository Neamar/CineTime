import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';
import 'package:cinetime/utils/_utils.dart';

class StarRating extends StatelessWidget {
  const StarRating({Key? key, required this.rating}) :
    assert(rating > 0),
    super(key: key);

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < rating.floor(); i ++)
          _buildStar(true),
        if (rating % 1 > 0.5)
          _buildPartialStar(rating % 1),
        for (var i = rating.round(); i < 5; i ++)
          _buildStar(false),
      ]..insertBetween(
        const SizedBox(width: 2, height: 2),
      ),
    );
  }

  Widget _buildStar(bool solid) {
    return Icon(
      solid ? CineTimeIcons.star : CineTimeIcons.star_empty,
      color: Colors.orange,
      size: 15,
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
