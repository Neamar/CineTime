import 'dart:math' as math;

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/movie_page.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

import '_widgets.dart';

class MovieTile extends StatelessWidget {
  const MovieTile({Key? key, required this.movieShowTimes, this.showTheaterName = true}) : super(key: key);

  final MovieShowTimes movieShowTimes;
  final bool showTheaterName;

  @override
  Widget build(BuildContext context) {
    // Display release year if movie is more than 6 month old
    final releaseDate = movieShowTimes.movie.releaseDate;
    int? releaseYear;
    if (releaseDate != null && ApiClient.mockedNow.difference(releaseDate) > Duration(days: 6 * 30))
      releaseYear = releaseDate.year;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        child: LayoutBuilder(
          builder: (context, box) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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

                        // Info line 1
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                textBaseline: TextBaseline.alphabetic,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                children: <Widget>[

                                  // Movie name
                                  Flexible(
                                    child: Text(
                                      movieShowTimes.movie.title,
                                      style: Theme.of(context).textTheme.headline6,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),

                                  // Release date
                                  if (releaseYear != null)
                                    Text('  ($releaseYear)'),
                                ],
                              ),
                            ),

                            // Rating
                            if (movieShowTimes.movie.rating != null && movieShowTimes.movie.rating! > 0)...[
                              AppResources.spacerLarge,
                              StarRating(
                                rating: movieShowTimes.movie.rating!,
                              ),
                            ],
                          ],
                        ),

                        // Info line 2
                        AppResources.spacerTiny,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(movieShowTimes.movie.genres!),    //TODO smaller
                            if (movieShowTimes.movie.duration != null)
                              Text(movieShowTimes.movie.duration!),
                          ],
                        ),

                        // Show time summary
                        Spacer(),
                        AppResources.spacerTiny,
                        for (var i = 0; i < math.min(movieShowTimes.theatersShowTimes.length, 2); i++)
                          Builder(
                            builder: (context) {
                              final theaterShowTimes = movieShowTimes.theatersShowTimes[i];

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[

                                  // Theater name
                                  Flexible(
                                    child: Text(
                                      showTheaterName ? theaterShowTimes.theater.name : '',
                                      style: Theme.of(context).textTheme.caption,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),

                                  // Show time summary
                                  AppResources.spacerMedium,
                                  Text(
                                    theaterShowTimes.showTimesSummary!,
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
        onTap: () => navigateTo(context, (_) => MoviePage(movieShowTimes)),
      ),
    );
  }
}
