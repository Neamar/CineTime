import 'dart:collection';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/dialogs/showtime_dialog.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:value_stream/value_stream.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _contentPadding = 16.0;

class MoviePage extends StatelessWidget {
  MoviePage(this.moviesShowTimes, this.initialIndex);

  final List<MovieShowTimes> moviesShowTimes;
  final int initialIndex;

  late final _pageController = PageController(initialPage: initialIndex);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: moviesShowTimes.length,
      itemBuilder: (context, index) => _MoviePageContent(moviesShowTimes[index]),
    );
  }
}

class _MoviePageContent extends StatefulWidget {
  const _MoviePageContent(this.movieShowTimes);

  final MovieShowTimes movieShowTimes;

  @override
  State<_MoviePageContent> createState() => _MoviePageContentState();
}

class _MoviePageContentState extends State<_MoviePageContent> with BlocProvider<_MoviePageContent, MoviePageBloc> {
  @override
  initBloc() => MoviePageBloc(widget.movieShowTimes);

  @override
  Widget build(BuildContext context) {
    const double overlapContentHeight = 50;

    final hasTrailer = widget.movieShowTimes.movie.trailerId != null;
    final poster = widget.movieShowTimes.movie.poster;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          ScalingHeader(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(widget.movieShowTimes.movie.title),
            flexibleSpace: CtCachedImage(
              path: poster,
              placeHolderBackground: true,
              onPressed: _openPoster,
              isThumbnail: false,
              applyDarken: true,
            ),
            overlapContentHeight: overlapContentHeight,
            overlapContentRadius: overlapContentHeight / 2,
            overlapContentBackgroundColor: AppResources.colorDarkRed,
            overlapContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: hasTrailer ? _openTrailer : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.ondemand_video_outlined,
                          color: hasTrailer ? Colors.white : AppResources.colorGrey,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Bande annonce',
                          style: TextStyle(color: hasTrailer ? Colors.white : AppResources.colorGrey),
                        )
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openMovieDataSheetWebPage,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Fiche',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[

                // Movie info
                Padding(
                  padding: const EdgeInsets.all(_contentPadding).copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      // Movie info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[

                          // Poster
                          if (poster != null)...[
                            SizedBox(
                              height: 100,
                              child: GestureDetector(
                                onTap: _openPoster,
                                child: HeroPoster(
                                  posterPath: poster,
                                  borderRadius: AppResources.borderRadiusTiny,
                                ),
                              ),
                            ),
                            AppResources.spacerMedium,
                          ],

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  widget.movieShowTimes.movie.title,
                                  style: context.textTheme.titleLarge,
                                ),
                                if (widget.movieShowTimes.movie.directors != null)
                                  TextWithLabel(
                                    label: 'De',
                                    text: widget.movieShowTimes.movie.directors!,
                                  ),
                                if (widget.movieShowTimes.movie.actors != null)
                                  TextWithLabel(
                                    label: 'Avec',
                                    text: widget.movieShowTimes.movie.actors!,
                                  ),
                                if (widget.movieShowTimes.movie.genres != null)
                                  TextWithLabel(
                                    label: 'Genre',
                                    text: widget.movieShowTimes.movie.genres!,
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (widget.movieShowTimes.movie.releaseDate != null)
                                      TextWithLabel(
                                        label: 'Sortie',
                                        text: widget.movieShowTimes.movie.releaseDateDisplay!,
                                      ),
                                    if (widget.movieShowTimes.movie.durationDisplay != null)
                                      TextWithLabel(
                                        label: 'Durée',
                                        text: widget.movieShowTimes.movie.durationDisplay!,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Rating
                      AppResources.spacerMedium,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (widget.movieShowTimes.movie.usersRating != null)
                            _buildRatingWidget('Spectateurs', widget.movieShowTimes.movie.usersRating!),
                          if (widget.movieShowTimes.movie.pressRating != null)
                            _buildRatingWidget('Presse', widget.movieShowTimes.movie.pressRating!),
                        ],
                      ),

                      // Synopsis
                      AppResources.spacerMedium,
                      SynopsisWidget(
                        movieId: widget.movieShowTimes.movie.id,
                      ),

                    ],
                  ),
                ),

                // Show times
                AppResources.spacerMedium,
                DataStreamBuilder<ShowTimeSpec>(
                  stream: bloc.selectedSpec,
                  builder: (context, filter) {
                    return Material(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[

                          // Header
                          Padding(
                            padding: const EdgeInsets.all(_contentPadding).copyWith(bottom: 0),
                            child: Row(
                              children: <Widget>[

                                // Title
                                Text(
                                  'Séances',
                                  style: context.textTheme.headlineSmall,
                                ),

                                // Filters
                                AppResources.spacerSmall,
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IntrinsicWidth(
                                      child: FadingEdgeScrollView.fromSingleChildScrollView(
                                        // gradientFractionOnStart: 0.5,    // TODO Doesn't work for now https://github.com/mponkin/fading_edge_scrollview/issues/2
                                        gradientFractionOnEnd: 0.5,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          controller: ScrollController(),  // FadingEdgeScrollView needs a controller set
                                          child: _TagFilterSelector(
                                            options: widget.movieShowTimes.showTimesSpecOptions,
                                            selected: filter,
                                            onChanged: (value) {
                                              bloc.selectedSpec.add(value);
                                              AnalyticsService.trackEvent('Movie spec changed', {
                                                'value': value.toString(),
                                                'availableSpec': widget.movieShowTimes.showTimesSpecOptions.map((s) => s.toString()).join(','),
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                          // Content
                          AppResources.spacerSmall,
                          ...bloc.getFormattedShowTimes(filter).map((theaterShowTimes) {
                            return TheaterShowTimesWidget(
                              theaterName: theaterShowTimes.theater.name,
                              showTimes: theaterShowTimes.formattedShowTimes,
                              filterName: filter.toString(),
                              scrollController: bloc.theaterShowTimesScrollControllers[theaterShowTimes.theater]!,
                              onShowtimePressed: (showtime) => ShowtimeDialog.open(
                                context: context,
                                movie: widget.movieShowTimes.movie,
                                theater: theaterShowTimes.theater,
                                showtime: showtime,
                              ),
                            );
                          }),
                          AppResources.spacerMedium,

                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingWidget(String title, double rating) {
    // TODO test with in-row icons instead of title
    // https://fontawesome.com/icons/newspaper?style=regular
    // https://fontawesome.com/icons/users?style=solid

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Text(
              title,
            ),
            AppResources.spacerSmall,
            Row(
              children: <Widget>[
                StarRating(rating),
                AppResources.spacerSmall,
                Text(
                  rating.toStringAsFixed(1),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openPoster() => navigateTo(context, (_) => PosterPage(widget.movieShowTimes.movie.poster!));

  void _openTrailer() {
    navigateTo(context, (_) => TrailerPage(widget.movieShowTimes.movie.trailerId!));
    AnalyticsService.trackEvent('Trailer displayed', {
      'movieTitle': widget.movieShowTimes.movie.title,
    });
  }

  void _openMovieDataSheetWebPage() {
    launchUrlString(ApiClient.getMovieUrl(widget.movieShowTimes.movie.id));
    AnalyticsService.trackEvent('Movie datasheet webpage displayed', {
      'movieTitle': widget.movieShowTimes.movie.title,
    });
  }
}

class HeroPoster extends StatelessWidget {
  const HeroPoster({super.key, this.posterPath, required this.borderRadius});

  final String? posterPath;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = CtCachedImage(
      path: posterPath,
      isThumbnail: true,
    );

    final staticContent = ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );

    if (posterPath != null)
      return Hero(
        tag: posterPath!,
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          final from = ((fromHeroContext.widget as Hero).child as ClipRRect).borderRadius;
          final to = ((toHeroContext.widget as Hero).child as ClipRRect).borderRadius;
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: flightDirection == HeroFlightDirection.push
                  ? Tween(begin: from, end: to).evaluate(animation)
                  : Tween(begin: to, end: from).evaluate(animation),
                child: child,
              );
            },
            child: child,
          );
        },
        child: staticContent,
      );

    return staticContent;
  }
}

class SynopsisWidget extends StatelessWidget {
  static const collapsedHeight = 80.0;

  const SynopsisWidget({super.key, required this.movieId});

  final ApiId movieId;

  @override
  Widget build(BuildContext context) {
    return FetchBuilder.basic<MovieInfo>(
      task: () => AppService.api.getMovieInfo(movieId),
      isDense: true,
      fetchingBuilder: (context) {
        return SizedBox(
          height: collapsedHeight,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(3, (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              )),
            ),
          ),
        );
      },
      builder: (context, info) {
        return ShowMoreText(
          header: info.certificate,
          text: info.synopsis ?? '\nAucun synopsis\n',
          collapsedHeight: collapsedHeight,
        );
      },
    );
  }
}

class _TagFilterSelector extends StatelessWidget {
  const _TagFilterSelector({required this.options, required this.selected, this.onChanged});

  final List<ShowTimeSpec> options;
  final ShowTimeSpec selected;
  final ValueChanged<ShowTimeSpec>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: options.map((option) => option == selected).toList(growable: false),
      constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
      borderRadius: BorderRadius.circular(5),
      onPressed: (int index) {
        final tapped = options[index];
        if (tapped != selected) onChanged?.call(tapped);
      },
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.all(5),
          child: Text(option.toString()),
        );
      }).toList(growable: false),
    );
  }
}

class TheaterShowTimesWidget extends StatelessWidget {
  const TheaterShowTimesWidget({
    super.key,
    required this.theaterName,
    required this.showTimes,
    required this.filterName,
    required this.scrollController,
    this.onShowtimePressed,
  });

  final String theaterName;
  final List<DayShowTimes> showTimes;
  final String filterName;
  final ScrollController scrollController;
  final ValueChanged<ShowTime>? onShowtimePressed;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = EdgeInsets.symmetric(horizontal: _contentPadding);
    final padding = horizontalPadding + const EdgeInsets.symmetric(vertical: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        // Theater name
        Padding(
          padding: horizontalPadding,
          child: Text(
            theaterName,
            style: context.textTheme.titleLarge,
          ),
        ),

        // Showtimes
        if (showTimes.every((dst) => dst.showTimes.isEmpty))
          Padding(
            padding: padding,
            child: Text('Aucune séance en $filterName', style: const TextStyle(color: AppResources.colorGrey)),
          )
        else
          FadingEdgeScrollView.fromSingleChildScrollView(
            gradientFractionOnEnd: 0.2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              padding: padding,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,   // Ensure uniform height, some items may be empty
                  children: showTimes.mapIndexed<Widget>((index, dayShowTimes) {
                    return _DayShowTimes(
                      day: dayShowTimes.date,
                      showtimes: dayShowTimes.showTimes,
                      isEven: index.isEven,
                      onPressed: onShowtimePressed,
                    );
                  }).toList()..insertBetween(AppResources.spacerTiny),
                ),
              ),
            ),
          ),
        AppResources.spacerSmall,
      ],
    );
  }
}

class _DayShowTimes extends StatelessWidget {
  const _DayShowTimes({
    required this.day,
    required this.showtimes,
    required this.isEven,
    this.onPressed,
  });

  final Date day;
  final List<ShowTime?> showtimes;
  final bool isEven;
  final ValueChanged<ShowTime>? onPressed;

  @override
  Widget build(BuildContext context) {
    // Compute width of a time text to be sure it's uniform, even if it's empty or smaller than the others
    final textPainter = TextPainter(
      text: const TextSpan(text: '22:22'),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textWidth = textPainter.size.width;

    // Theme
    final headerForegroundColor = showtimes.isEmpty ? AppResources.colorGrey : null;

    // Build widget
    return Material(
      color: () {
        if (day == AppService.now.toDate) return AppResources.colorLightRed;
        if (isEven) return Theme.of(context).scaffoldBackgroundColor;
      } (),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(6),
        width: textWidth,   // Ensure uniform width (may be empty or smaller than others)
        child: Column(
          children: [
            // Week day
            Text(
              AppResources.weekdayNames[day.weekday]!,
              style: context.textTheme.titleMedium?.copyWith(color: headerForegroundColor),
            ),

            // Day
            AppResources.spacerTiny,
            Text(
              day.day.toString(),
              style: context.textTheme.titleLarge?.copyWith(color: headerForegroundColor),
            ),

            // Times
            AppResources.spacerSmall,
            ...showtimes.map<Widget>((showtime) {
              final formattedShowtime = showtime?.dateTime.toTime.toString();
              final text = Text(
                formattedShowtime ?? '-',
              );
              if (formattedShowtime == null) return text;
              return InkWell(
                onTap: onPressed != null ? () => onPressed!(showtime!) : null,
                child: text,
              );
            }).toList()..insertBetween(AppResources.spacerExtraTiny),

          ],
        ),
      ),
    );
  }
}


class MoviePageBloc with Disposable {
  MoviePageBloc(this.movieShowTimes) :
    selectedSpec = DataStream(movieShowTimes.showTimesSpecOptions.first) {
    AnalyticsService.trackEvent('Movie displayed', {
      'movieTitle': movieShowTimes.movie.title,
      'theaterCount': movieShowTimes.theatersShowTimes.length,
      'theatersId': movieShowTimes.theatersShowTimes.map((tst) => tst.theater).toIdListString(),
      'availableSpec': movieShowTimes.showTimesSpecOptions.map((s) => s.toString()).join(','),
    });
  }

  final MovieShowTimes movieShowTimes;

  final DataStream<ShowTimeSpec> selectedSpec;

  /// Simple cache for [getFormattedShowTimes]
  final _formattedShowTimes = <ShowTimeSpec, List<FormattedTheaterShowTimes>>{};

  /// List of [FormattedTheaterShowTimes] for this [filter].
  /// With simple caching system.
  List<FormattedTheaterShowTimes> getFormattedShowTimes(ShowTimeSpec filter) {
    return _formattedShowTimes.putIfAbsent(filter, () {
      // Compute days with show
      final daysWithShow = SplayTreeSet<Date>();
      for (final theaterShowTimes in movieShowTimes.theatersShowTimes) {
        daysWithShow.addAll(theaterShowTimes.getFilteredDayWithShow(filter));
      }

      // Build list of FormattedTheaterShowTimes
      return movieShowTimes.theatersShowTimes.map((tst) {
        return FormattedTheaterShowTimes(tst.theater, tst.getFilteredShowTimes(filter), daysWithShow);
      }).toList(growable: false);
    });
  }

  final theaterShowTimesScrollControllerMaster = LinkedScrollControllerGroup();
  late final theaterShowTimesScrollControllers = () {
    final controllers = <Theater, ScrollController>{};
    for (final theaterShowTimes in movieShowTimes.theatersShowTimes) {
      controllers[theaterShowTimes.theater] = theaterShowTimesScrollControllerMaster.addAndGet();
    }
    return controllers;
  } ();

  @override
  void dispose() {
    selectedSpec.close();
    theaterShowTimesScrollControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }
}

class FormattedTheaterShowTimes {
  FormattedTheaterShowTimes(this.theater, List<ShowTime> showTimes, Set<Date> datesWithShow) {
    formattedShowTimes = () {
      // List all different times
      final timesRef = SplayTreeSet.of(showTimes.map((st) => st.dateTime.toTime));

      // Build a map of <time reference, index>
      final timesRefMap = Map.fromIterables(timesRef, List.generate(timesRef.length, (index) => index));

      // Organise showtimes per day
      final showTimesMap = SplayTreeMap<Date, DayShowTimes>();
      for (final showTime in showTimes) {
        final date = showTime.dateTime.toDate;
        final time = showTime.dateTime.toTime;

        // Get day list or create it
        final dayShowTimes = showTimesMap.putIfAbsent(date, () => DayShowTimes(date, List.filled(timesRef.length, null, growable: false)));

        // Set showTime at right index
        dayShowTimes.showTimes[timesRefMap[time]!] = showTime;
      }

      // Add remaining empty dates (without show), so that all theaters have the same dates for visual alignment
      for (final date in datesWithShow) {
        showTimesMap.putIfAbsent(date, () => DayShowTimes(date, List.empty()));
      }

      // Return value
      return showTimesMap.values.toList(growable: false);
    } ();
  }

  /// Theater data
  final Theater theater;

  /// Formatted list of [DayShowTimes].
  late final List<DayShowTimes> formattedShowTimes;
}
