import 'dart:math' as math;

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/movie_page.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/material.dart';

import '_widgets.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.moviesShowTimes, required this.movieIndex, this.showTheaterName = true, this.preferredRatingType});

  final List<MovieShowTimes> moviesShowTimes;
  final int movieIndex;
  final bool showTheaterName;
  final MovieRatingType? preferredRatingType;

  @override
  Widget build(BuildContext context) {
    final movieShowTimes = moviesShowTimes[movieIndex];

    // Rating
    final rating = movieShowTimes.movie.getRating(preferredType: preferredRatingType);

    // Build widget
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => navigateTo(context, (_) => MoviePage(moviesShowTimes, movieIndex)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

                                  // Release year
                                  if (movieShowTimes.movie.releaseYearDisplay != null)
                                    Text('  ${movieShowTimes.movie.releaseYearDisplay}'),
                                ],
                              ),
                            ),

                            // Rating
                            if (rating != null && rating > 0)...[
                              AppResources.spacerLarge,
                              StarRating(rating),
                            ]

                            // Country
                            else if (movieShowTimes.movie.countryDisplay != null)...[
                              AppResources.spacerLarge,
                              Text(movieShowTimes.movie.countryDisplay!),
                            ],
                          ],
                        ),

                        // Info line 2
                        AppResources.spacerTiny,
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: () {
                                final genres = movieShowTimes.movie.genres;
                                if (genres != null) {
                                  return Text(
                                    genres,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }
                                final actors = movieShowTimes.movie.actors;
                                if (actors != null) {
                                  return TextWithLabel(
                                    label: 'avec',
                                    text: actors,
                                    singleLine: true,
                                  );
                                }
                                return const SizedBox();
                              } (),
                            ),
                            if (movieShowTimes.movie.durationDisplay != null)...[
                              AppResources.spacerSmall,
                              Text(movieShowTimes.movie.durationDisplay!),
                            ],
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
                                    theaterShowTimes.showTimesSummary,
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
      ),
    );
  }
}
