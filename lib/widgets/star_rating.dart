import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cinetime/utils/_utils.dart';

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({Key? key, required this.rating}) :
    assert(rating > 0),
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < rating.floor(); i ++)
          _buildStar(FontAwesomeIcons.solidStar),
        if (rating % 1 > 0.5)
          _buildStar(FontAwesomeIcons.starHalfAlt),
        for (var i = rating.round(); i < 5; i ++)
          _buildStar(FontAwesomeIcons.star),
      ]..insertBetween(
        const SizedBox(width: 2, height: 2),
      ),
    );
  }

  Widget _buildStar(IconData icon) {
    return FaIcon(
      icon,
      color: Colors.orange,
      size: 15,
    );
  }
}
