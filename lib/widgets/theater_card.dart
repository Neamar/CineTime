import 'package:cinetime/models/theater.dart';
import 'package:cinetime/pages/movies_page.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:flutter/material.dart';

class TheaterCard extends StatefulWidget {
  const TheaterCard({Key? key, required this.theater, this.multiSelectionMode = false}) : super(key: key);

  /// Theater
  final Theater theater;

  /// If false, it will clear selection, select [theater] and pop when pressed.
  /// If true, it will display a checkbox, and just select/unselect this [theater] when pressed.
  final bool multiSelectionMode;

  @override
  State<TheaterCard> createState() => _TheaterCardState();
}

class _TheaterCardState extends State<TheaterCard> {
  bool isSelected = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[

          // Main content
          InkWell(
            child: Row(
              children: <Widget>[

                // Leading
                SizedBox(
                  width: 60,
                  child: widget.multiSelectionMode
                    ? IgnorePointer(
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) {},
                        ),
                      )
                    : Icon(
                        Icons.theaters,
                        size: 50,
                      ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          widget.theater.name,
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                        Spacer(),
                        if (widget.theater.distanceDisplay != null)
                          Text(
                            widget.theater.distanceDisplay!,
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        Text(
                          widget.theater.fullAddress,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            onTap: _onSelected,
          ),

          // Star button
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: isFavorite ? Theme.of(context).primaryColor : Colors.white,
              shape: CornerBorder(CornerBorderPosition.topRight),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: SizedBox.fromSize(
                size: Size.square(50),
                child: InkWell(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.white : Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  onTap: _onFavoriteTap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected() async {
    if (widget.multiSelectionMode) {
      // Save value
      if (isSelected)
        await AppService.instance.unselectTheater(widget.theater);
      else
        await AppService.instance.selectTheater(widget.theater);

      // Update UI
      setState(() {
        _refreshStatus();
      });
    } else {
      // Save value
      await AppService.instance.selectTheater(widget.theater, clearFirst: true);

      // Update UI
      if (context.canPop)
        Navigator.of(context).pop(!widget.multiSelectionMode);
      else
        navigateTo(context, (_) => MoviesPage(), clearHistory: true);
    }
  }

  Future<void> _onFavoriteTap() async {
    // Save value
    if (isFavorite)
      await AppService.instance.removeFromFavorites(widget.theater);
    else
      await AppService.instance.addToFavorites(widget.theater);

    // Update UI
    setState(() {
      _refreshStatus();
    });
  }

  void _refreshStatus() {
    isSelected = AppService.instance.isSelected(widget.theater);
    isFavorite = AppService.instance.isFavorite(widget.theater);
  }
}
