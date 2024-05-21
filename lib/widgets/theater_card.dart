import 'package:cinetime/models/theater.dart';
import 'package:cinetime/pages/movies_page.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:flutter/material.dart';

class TheaterCard extends StatefulWidget {
  static const height = 85.0;     // Allow 3 lines addresses to fit

  const TheaterCard({super.key, required this.theater, this.multiSelectionMode = false, this.onLongPress});

  /// Theater
  final Theater theater;

  /// If false, it will clear selection, select [theater] and pop when pressed.
  /// If true, it will display a checkbox, and just select/unselect this [theater] when pressed.
  final bool multiSelectionMode;

  /// Only enabled if [multiSelectionMode] is false.
  /// On a long press, it will select [theater] and then call [onLongPress].
  final VoidCallback? onLongPress;

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
            onTap: _onSelected,
            onLongPress: widget.multiSelectionMode || widget.onLongPress == null  ? null : _onLongPress,
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
                    : const Icon(
                        CineTimeIcons.videocam,
                        color: AppResources.colorDarkRed,
                      ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: [
                            // Theater name
                            Flexible(
                              child: Text(
                                widget.theater.name,
                                style: context.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Distance
                            if (widget.theater.distanceDisplay != null)
                              Text(
                                ' à ${widget.theater.distanceDisplay!}',
                                style: context.textTheme.bodyMedium?.copyWith(color: context.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              ),

                            // Spacer for favorite button
                            const SizedBox(width: 35),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          widget.theater.fullAddress,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Star button
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: isFavorite ? Theme.of(context).primaryColor : AppResources.colorGrey,
              shape: const CornerBorder(CornerBorderPosition.topRight),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: SizedBox.fromSize(
                size: const Size.square(50),
                child: InkWell(
                  onTap: _onFavoriteTap,
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
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
      if (mounted) {
        if (context.canPop)
          Navigator.of(context).pop(!widget.multiSelectionMode);
        else
          navigateTo(context, (_) => const MoviesPage(), clearHistory: true);
      }
    }
  }

  Future<void> _onLongPress() async {
    // Save value
    await AppService.instance.selectTheater(widget.theater);

    // Update UI
    setState(() {
      _refreshStatus();
    });

    // Callback
    widget.onLongPress?.call();
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
