import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        _buildPartialStar(rating % 1),
        for (var i = rating.ceil(); i < 5; i ++)
          _buildStar(false),
      ]..insertBetween(
        const SizedBox(width: 2, height: 2),
      ),
    );
  }

  Widget _buildStar(bool solid) {
    return FaIcon(
      solid ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
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
