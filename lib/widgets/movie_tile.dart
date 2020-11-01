import 'dart:math' as math;

import 'package:cinetime/helpers/tools.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';

import '_widgets.dart';

class MovieTile extends StatelessWidget {
  final MovieShowTimes movieShowTimes;
  final VoidCallback onPressed;

  const MovieTile({Key key, this.movieShowTimes, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Display release year if movie is more than 6 month old
    var releaseDate = movieShowTimes.movie.releaseDate;
    int releaseYear;
    if (releaseDate != null && DateTime.now().difference(releaseDate) > Duration(days: 6 * 30))
      releaseYear = releaseDate.year;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        child: LayoutBuilder(
          builder: (context, box) {
            return Row(
              children: <Widget>[

                // Poster
                SizedBox(
                  width: box.maxHeight * 0.75,
                  child: CtCachedImage(
                    path: movieShowTimes.movie.poster,
                    isThumbnail: true,
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                textBaseline: TextBaseline.alphabetic,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      movieShowTimes.movie.title,
                                      style: Theme.of(context).textTheme.title,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                  if (releaseYear != null)
                                    Text('  ($releaseYear)'),
                                ],
                              ),
                            ),
                            if (movieShowTimes.movie.rating != null && movieShowTimes.movie.rating > 0)
                              ...[
                                AppResources.WidgetSpacerLarge,
                                StarRating(
                                  rating: movieShowTimes.movie.rating,
                                )
                              ],
                          ],
                        ),
                        AppResources.WidgetSpacerTiny,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(movieShowTimes.movie.genres),    //TODO smaller
                            Text(movieShowTimes.movie.durationDisplay),
                          ],
                        ),
                        Spacer(),
                        for (var i = 0; i < math.min(movieShowTimes.theatersShowTimes.length, 2); i++)
                          Builder(
                            builder: (context) {
                              var theaterShowTimes = movieShowTimes.theatersShowTimes[i];

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      theaterShowTimes.theater.name,
                                      style: Theme.of(context).textTheme.caption,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                  AppResources.WidgetSpacerMedium,
                                  Text(
                                    theaterShowTimes.showTimesSummary,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              );
                            }
                          ),
                      ],
                    ),
                  ),
                )
              ],
            );
          }
        ),
        onTap: onPressed,
      ),
    );
  }
}