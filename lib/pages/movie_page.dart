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
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MoviePage extends StatefulWidget {
  const MoviePage(this.movieShowTimes);

  final MovieShowTimes movieShowTimes;

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> with BlocProvider<MoviePage, MoviePageBloc> {
  @override
  initBloc() => MoviePageBloc(widget.movieShowTimes);

  @override
  Widget build(BuildContext context) {
    const double contentPadding = 16;
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
                          CineTimeIcons.link_ext,
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
                  padding: const EdgeInsets.all(contentPadding).copyWith(bottom: 0),
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
                          if (widget.movieShowTimes.movie.pressRating != null)
                            _buildRatingWidget('Presse', widget.movieShowTimes.movie.pressRating!),
                          if (widget.movieShowTimes.movie.userRating != null)
                            _buildRatingWidget('Spectateur', widget.movieShowTimes.movie.userRating!),
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
                BehaviorSubjectBuilder<ShowTimeSpec>(
                  subject: bloc.selectedSpec,
                  builder: (context, snapshot) {
                    final filter = snapshot.data!;
                    return Material(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[

                          // Header
                          Padding(
                            padding: const EdgeInsets.all(contentPadding).copyWith(bottom: 0),
                            child: Row(
                              children: <Widget>[

                                // Title
                                Text(
                                  'Séances',
                                  style: context.textTheme.titleLarge,
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
                          AppResources.spacerLarge,
                          ...widget.movieShowTimes.theatersShowTimes.map((theaterShowTimes) {
                            return FadingEdgeScrollView.fromSingleChildScrollView(
                              gradientFractionOnEnd: 0.2,
                              child: SingleChildScrollView(
                                controller: ScrollController(),  // FadingEdgeScrollView needs a controller set
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal:  contentPadding),
                                    child: TheaterShowTimesWidget(
                                      theaterName: theaterShowTimes.theater.name,
                                      showTimes: theaterShowTimes.getFormattedShowTimes(filter),
                                      filterName: filter.toString(),
                                      onShowtimePressed: (showtime) => ShowtimeDialog.open(
                                        context: context,
                                        movie: widget.movieShowTimes.movie,
                                        theater: theaterShowTimes.theater,
                                        showtime: showtime,
                                      ),
                                    ),
                                  ),
                                ),
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
    this.onShowtimePressed,
  });

  final String theaterName;
  final List<DayShowTimes> showTimes;
  final String filterName;
  final ValueChanged<ShowTime>? onShowtimePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        // Theater name
        Text(
          theaterName,
          style: context.textTheme.titleLarge,
        ),

        // Showtimes
        AppResources.spacerSmall,
        if (showTimes.isNotEmpty)
          Row(
            children: showTimes.mapIndexed<Widget>((index, dayShowTimes) {
              return _DayShowTimes(
                day: dayShowTimes.date,
                showtimes: dayShowTimes.showTimes,
                backgroundColor: () {
                  if (dayShowTimes.date == AppService.now.toDate) return AppResources.colorLightRed;
                  if (index.isEven) return Theme.of(context).scaffoldBackgroundColor;
                } (),
                onPressed: onShowtimePressed,
              );
            }).toList()..insertBetween(AppResources.spacerTiny),
          )
        else
          Text('Aucune séance en $filterName'),
        AppResources.spacerLarge,
      ],
    );
  }
}

class _DayShowTimes extends StatelessWidget {
  const _DayShowTimes({
    required this.day,
    required this.showtimes,
    this.backgroundColor,
    this.onPressed,
  });

  final Date day;
  final List<ShowTime?> showtimes;
  final Color? backgroundColor;
  final ValueChanged<ShowTime>? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          // Week day
          Text(
            AppResources.weekdayNames[day.weekday]!,
            style: context.textTheme.titleMedium,
          ),

          // Day
          AppResources.spacerTiny,
          Text(
            day.day.toString(),
            style: context.textTheme.titleLarge,
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
    );
  }
}


class MoviePageBloc with Disposable {
  MoviePageBloc(MovieShowTimes movieShowTimes) :
    selectedSpec = BehaviorSubject.seeded(movieShowTimes.showTimesSpecOptions.first) {
    AnalyticsService.trackEvent('Movie displayed', {
      'movieTitle': movieShowTimes.movie.title,
      'theaterCount': movieShowTimes.theatersShowTimes.length,
      'theatersId': movieShowTimes.theatersShowTimes.map((tst) => tst.theater).toIdListString(),
      'availableSpec': movieShowTimes.showTimesSpecOptions.map((s) => s.toString()).join(','),
    });
  }

  final BehaviorSubject<ShowTimeSpec> selectedSpec;

  @override
  void dispose() {
    selectedSpec.close();
    super.dispose();
  }
}