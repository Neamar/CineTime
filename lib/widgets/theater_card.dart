import 'package:cinetime/models/theater.dart';
import 'package:cinetime/pages/movies_page.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:fetcher/fetcher_bloc.dart';
import 'package:flutter/material.dart';

class TheaterCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[

          // Main content
          InkWell(
            onTap: () => _onSelected(context),
            onLongPress: multiSelectionMode || onLongPress == null  ? null : _onLongPress,
            child: Row(
              children: <Widget>[

                // Leading
                SizedBox(
                  width: 60,
                  child: multiSelectionMode
                    ? IgnorePointer(
                        child: DataStreamBuilder(
                          stream: AppService.instance.selectedTheaters,
                          builder: (context, selectedTheaters) {
                            return Checkbox(
                              value: selectedTheaters.contains(theater),
                              onChanged: (_) {},
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.theaters_outlined,
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
                                theater.name,
                                style: context.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Distance
                            if (theater.distanceDisplay != null)
                              Text(
                                ' à ${theater.distanceDisplay!}',
                                style: context.textTheme.bodyMedium?.copyWith(color: context.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              ),

                            // Spacer for favorite button
                            const SizedBox(width: 35),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          theater.fullAddress,
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
            child: DataStreamBuilder(
              stream: AppService.instance.favoriteTheaters,
              builder: (context, favoriteTheaters) {
                return Material(
                  color: favoriteTheaters.contains(theater) ? Theme.of(context).primaryColor : AppResources.colorGrey,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // UI is updated by listening to AppService streams, which are updated synchronously (saving is handled by AppService).

  void _onSelected(BuildContext context) {
    if (multiSelectionMode) {
      if (AppService.instance.isSelected(theater))
        AppService.instance.unselectTheater(theater);
      else
        AppService.instance.selectTheater(theater);
    } else {
      AppService.instance.selectTheater(theater, clearFirst: true);

      if (context.canPop)
        Navigator.of(context).pop(true);
      else
        navigateTo(context, (_) => const MoviesPage(), clearHistory: true);
    }
  }

  void _onLongPress() {
    AppService.instance.selectTheater(theater);
    onLongPress?.call();
  }

  void _onFavoriteTap() {
    if (AppService.instance.isFavorite(theater))
      AppService.instance.removeFromFavorites(theater);
    else
      AppService.instance.addToFavorites(theater);
  }
}
