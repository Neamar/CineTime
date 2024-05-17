import 'dart:math' as math;

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/movie_page.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

import '_widgets.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movieShowTimes, this.showTheaterName = true});

  final MovieShowTimes movieShowTimes;
  final bool showTheaterName;

  @override
  Widget build(BuildContext context) {
    // Display release year if movie is more than 6 month old
    final releaseDate = movieShowTimes.movie.releaseDate;
    int? releaseYear;
    if (releaseDate != null && AppService.now.difference(releaseDate) > const Duration(days: 6 * 30))
      releaseYear = releaseDate.year;

    return Card(
      child: InkWell(
        child: LayoutBuilder(
          builder: (context, box) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[

                // Poster
                SizedBox(
                  width: box.maxHeight * 0.75,
                  child: HeroPoster(
                    posterPath: movieShowTimes.movie.poster,
                    borderRadius: BorderRadius.only(
                      topLeft: AppResources.borderRadiusTiny.topLeft,
                      bottomLeft: AppResources.borderRadiusTiny.bottomLeft,
                    ),
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
                                      style: context.textTheme.titleLarge,
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
                              StarRating(movieShowTimes.movie.rating!),
                            ],
                          ],
                        ),

                        // Info line 2
                        AppResources.spacerTiny,
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                movieShowTimes.movie.genres!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (movieShowTimes.movie.durationDisplay != null)
                              Text(movieShowTimes.movie.durationDisplay!),
                          ],
                        ),

                        // Show time summary
                        const Spacer(),
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
                                      style: context.textTheme.bodySmall,
                                      softWrap: false,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),

                                  // Show time summary
                                  AppResources.spacerMedium,
                                  Text(
                                    theaterShowTimes.showTimesSummary!,
                                    style: context.textTheme.bodySmall,
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
