import 'dart:collection';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/dialogs/showtime_dialog.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:fetcher/fetcher_bloc.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
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

    final movie = widget.movieShowTimes.movie;
    final poster = movie.poster;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          ScalingHeader(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(movie.title),
            actions: [
              _MovieVisibilityToggleButton(widget.movieShowTimes.movie),
            ],
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
                  FetchBuilder<ApiId?>.snapshot(    // Keep the (disabled) button displayed while loading or on error
                    task: () => movie.trailerId ?? bloc.getMovieInfo().then((info) => info.trailerId),
                    snapshotBuilder: (context, snapshot) {
                      final trailerId = snapshot.data;
                      return AnimatedSwitcher(
                        duration: AppResources.durationAnimationMedium,
                        child: _TextIconButton(
                          key: ObjectKey(snapshot),
                          icon: Icons.ondemand_video_outlined,
                          label: 'Bande annonce',
                          onPressed: trailerId != null ? () => _openTrailer(trailerId) : null,
                        ),
                      );
                    },
                  ),
                  _TextIconButton(
                    icon: Icons.open_in_new,
                    label: 'Fiche',
                    onPressed: _openMovieDataSheetWebPage,
                  ),
                ],
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(
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
                                    movie.title,
                                    style: context.textTheme.titleLarge,
                                  ),
                                  if (movie.originalTitle != null)
                                    TextWithLabel(
                                      label: 'Original',
                                      text: movie.originalTitle!,
                                    ),
                                  if (movie.country != null)
                                    TextWithLabel(
                                      label: 'Pays',
                                      text: movie.country!,
                                    ),
                                  if (movie.directors != null)
                                    TextWithLabel(
                                      label: 'De',
                                      text: movie.directors!,
                                    ),
                                  if (movie.actors != null)
                                    TextWithLabel(
                                      label: 'Avec',
                                      text: movie.actors!,
                                    ),
                                  // Genres
                                  FetchBuilder<String?>.snapshot(
                                    task: () => movie.genres ?? bloc.getMovieInfo().then((info) => info.genres),
                                    snapshotBuilder: (context, snapshot) {
                                      final genres = snapshot.data;
                                      return CtAnimatedSwitcher(
                                        sizeAnimation: true,
                                        child: genres == null ? null : TextWithLabel(
                                          label: 'Genres',
                                          text: genres,
                                        ),
                                      );
                                    },
                                  ),
                                  if (movie.languages != null)
                                    TextWithLabel(
                                      label: 'Langues',
                                      text: movie.languages!,
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      FetchBuilder<DateTime?>.snapshot(
                                        task: () => movie.releaseDate ?? bloc.getMovieInfo().then((info) => info.releaseDate),
                                        snapshotBuilder: (context, snapshot) {
                                          final releaseDate = snapshot.data;
                                          return CtAnimatedSwitcher(
                                            sizeAnimation: true,
                                            child: releaseDate == null ? null : TextWithLabel(
                                              label: 'Sortie',
                                              text: releaseDate.toReleaseDateDisplay(),
                                            ),
                                          );
                                        },
                                      ),
                                      if (movie.durationDisplay != null)
                                        TextWithLabel(
                                          label: 'Durée',
                                          text: movie.durationDisplay!,
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
                        FetchBuilder<double?>(    // TODO handle hide animation (size transition). Maybe hide loader completly instead ? So only Synopsis has a loader & erorr display ?
                          task: () => movie.pressRating ?? bloc.getMovieInfo().then((info) => info.pressRating),
                          builder: (context, pressRating) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                if (movie.usersRating != null)
                                  _RatingWidget(
                                    icon: FontAwesomeIcons.users.data,
                                    rating: movie.usersRating!,
                                    tooltip: 'Spectateurs',
                                    iconSizeDelta: -3,
                                    onPressed: () => launchUrlString(movie.usersRatingUrl),
                                  ),
                                if (pressRating != null)
                                  _RatingWidget(
                                    icon: FontAwesomeIcons.newspaper.data,
                                    rating: pressRating,
                                    tooltip: 'Presse',
                                    onPressed: () => launchUrlString(movie.pressRatingUrl),
                                  ),
                              ],
                            );
                          },
                        ),

                        // Synopsis
                        AppResources.spacerMedium,
                        SynopsisWidget(
                          fetchMovieInfo: bloc.getMovieInfo,
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Séances',
                                        style: context.textTheme.headlineSmall,
                                      ),
                                      AppResources.spacerExtraTiny,
                                      Text(
                                        _getShowTimesCountLabel(filter),
                                        style: context.textTheme.bodySmall?.copyWith(color: AppResources.colorGrey),
                                      ),
                                    ],
                                  ),

                                  // Filters
                                  AppResources.spacerSmall,
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: IntrinsicWidth(
                                        child: _TagFilterSelector(
                                          optionsByAudioSubtitles: widget.movieShowTimes.showTimesSpecOptionsByAudioSubtitles,
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

                                ],
                              ),
                            ),

                            // Content
                            AppResources.spacerLarge,
                            ...bloc.getFormattedShowTimes(filter).map((theaterShowTimes) {
                              return TheaterShowTimesWidget(
                                theaterName: theaterShowTimes.theater.name,
                                showTimes: theaterShowTimes.formattedShowTimes,
                                filterName: AppService.api.showTimeSpecToDisplayString(filter),
                                scrollController: bloc.theaterShowTimesScrollControllers[theaterShowTimes.theater]!,
                                onShowtimePressed: (showtime) => ShowtimeDialog.open(
                                  context: context,
                                  movie: widget.movieShowTimes.movie,
                                  theater: theaterShowTimes.theater,
                                  showtime: showtime,
                                ),
                              );
                            }),

                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Examples: '36 séances sur 46', '46 séances', '1 séance'
  String _getShowTimesCountLabel(ShowTimeSpec filter) {
    final total = widget.movieShowTimes.showTimesCount;
    final filtered = widget.movieShowTimes.getFilteredShowTimesCount(filter);
    return filtered == total ? 'séance'.plural(total) : '${'séance'.plural(filtered)} sur $total';
  }

  void _openPoster() => navigateTo(context, (_) => PosterPage(widget.movieShowTimes.movie.poster!));

  void _openTrailer(ApiId trailerId) {
    navigateTo(context, (_) => TrailerPage(trailerId));
    AnalyticsService.trackEvent('Trailer displayed', {
      'movieTitle': widget.movieShowTimes.movie.title,
    });
  }

  void _openMovieDataSheetWebPage() {
    launchUrlString(widget.movieShowTimes.movie.movieUrl);
    AnalyticsService.trackEvent('Movie datasheet webpage displayed', {
      'movieTitle': widget.movieShowTimes.movie.title,
    });
  }
}

class _TextIconButton extends StatelessWidget {
  const _TextIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? Colors.white38 : Colors.white,
        ),
        overlayColor: WidgetStateProperty.all(Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon),
          SizedBox(width: 8.0),
          Text(label),
        ],
      ),
    );
  }
}

class _RatingWidget extends StatelessWidget {
  const _RatingWidget({
    required this.icon,
    required this.rating,
    required this.tooltip,
    this.iconSizeDelta,
    this.onPressed,
  });

  final IconData icon;
  final double rating;
  final String tooltip;
  final double? iconSizeDelta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20 + (iconSizeDelta ?? 0)),
                AppResources.spacerSmall,
                StarRating(rating),
                AppResources.spacerSmall,
                Text(rating.toStringAsFixed(1)),
              ],
            ),
          ),
        ),
      ),
    );
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

class _MovieVisibilityToggleButton extends StatefulWidget {
  const _MovieVisibilityToggleButton(this.movie);

  final Movie movie;

  @override
  State<_MovieVisibilityToggleButton> createState() => _MovieVisibilityToggleButtonState();
}

class _MovieVisibilityToggleButtonState extends State<_MovieVisibilityToggleButton> {
  @override
  Widget build(BuildContext context) {
    final isHidden = AppService.instance.isMovieHidden(widget.movie);
    return IconButton(
      icon: Icon(
        isHidden ? Icons.visibility_off : Icons.visibility,
      ),
      tooltip: isHidden ? 'Afficher le film' : 'Masquer le film',
      onPressed: () => setState(() {
        // It's better a boolean value than a toggle, to avoid issues if users click too fast
        if (isHidden) {
          AppService.instance.unHideMovie(widget.movie);
        } else {
          AppService.instance.hideMovie(widget.movie);
        }
      }),
    );
  }
}

class SynopsisWidget extends StatelessWidget {
  static const collapsedHeight = 80.0;

  const SynopsisWidget({super.key, required this.fetchMovieInfo});

  final Future<MovieInfo> Function() fetchMovieInfo;

  @override
  Widget build(BuildContext context) {
    return FetchBuilder<MovieInfo>(
      task: fetchMovieInfo,
      config: FetcherConfig(
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
      ),
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
  const _TagFilterSelector({required this.optionsByAudioSubtitles, required this.selected, this.onChanged});

  /// Available specs, grouped by audio version + subtitles (see [ShowTimeSpec.withoutTechnology])
  final Map<ShowTimeSpec, List<ShowTimeSpec>> optionsByAudioSubtitles;
  final ShowTimeSpec selected;
  final ValueChanged<ShowTimeSpec>? onChanged;

  static const _defaultTechnologyLabel = '2D';

  void _select(ShowTimeSpec spec) {
    if (spec != selected) onChanged?.call(spec);
  }

  @override
  Widget build(BuildContext context) {
    final selectedAudioSubtitles = selected.withoutTechnology;
    final technologyOptions = optionsByAudioSubtitles[selectedAudioSubtitles]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[

        // Audio + subtitles
        _buildToggleRow(
          values: optionsByAudioSubtitles.keys.toList(growable: false),
          selected: selectedAudioSubtitles,
          labelOf: AppService.api.showTimeAudioSubtitlesToDisplayString,
          onSelected: (audioSubtitles) {
            // Keep the current technology if available, otherwise fallback to the first one
            final specs = optionsByAudioSubtitles[audioSubtitles]!;
            _select(specs.firstWhereOrNull((spec) => spec.technology == selected.technology) ?? specs.first);
          },
        ),

        // Technology
        if (technologyOptions.any((spec) => spec.technology != null)) ...[
          AppResources.spacerTiny,
          _buildToggleRow(
            values: technologyOptions,
            selected: selected,
            labelOf: (spec) => spec.technology ?? _defaultTechnologyLabel,
            onSelected: _select,
          ),
        ],

      ],
    );
  }

  Widget _buildToggleRow<T>({required List<T> values, required T selected, required String Function(T) labelOf, required ValueChanged<T> onSelected}) {
    return FadingEdgeScrollView.fromSingleChildScrollView(
      // gradientFractionOnStart: 0.5,    // TODO Doesn't work for now https://github.com/mponkin/fading_edge_scrollview/issues/2
      gradientFractionOnEnd: 0.5,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: ScrollController(),  // FadingEdgeScrollView needs a controller set
        child: ToggleButtons(
          isSelected: values.map((value) => value == selected).toList(growable: false),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
          borderRadius: BorderRadius.circular(5),
          onPressed: (index) => onSelected(values[index]),
          children: values.map((value) {
            return Padding(
              padding: const EdgeInsets.all(5),
              child: Text(labelOf(value)),
            );
          }).toList(growable: false),
        ),
      ),
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
          () {
            // Compute width of a time text to be sure it's uniform, even if it's empty or smaller than the others
            final timeStyle = context.textTheme.bodyMedium;
            final textPainter = TextPainter(
              text: TextSpan(
                text: '22:22',
                style: timeStyle,
              ),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),   // Adapt to OS text scale
            )..layout();
            final textWidth = textPainter.size.width;

            // Build widget
            return FadingEdgeScrollView.fromSingleChildScrollView(
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
                        width: textWidth,
                        timeStyle: timeStyle,
                        onPressed: onShowtimePressed,
                      );
                    }).toList()..insertBetween(AppResources.spacerTiny),
                  ),
                ),
              ),
            );
          } (),
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
    required this.width,
    this.timeStyle,
    this.onPressed,
  });

  final Date day;
  final List<ShowTime?> showtimes;
  final bool isEven;
  final double width;
  final TextStyle? timeStyle;
  final ValueChanged<ShowTime>? onPressed;

  @override
  Widget build(BuildContext context) {
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
        width: width,   // Ensure uniform width (may be empty or smaller than others)
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
                style: timeStyle,
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

  /// Cache for [getMovieInfo]
  Future<MovieInfo>? _movieInfo;

  /// Single shared source of [MovieInfo] for this page, so every [FetchBuilder]-based widget
  /// that needs complementary movie info (rating fallback, info lines, synopsis, ...) can consume
  /// it independently while only ever triggering a single network request.
  /// Memoized in memory (a failed request isn't kept, so the next call retries).
  Future<MovieInfo> getMovieInfo() => _movieInfo ??= _fetchMovieInfo();

  Future<MovieInfo> _fetchMovieInfo() async {
    try {
      return await AppService.api.getMovieInfo(movieShowTimes.movie.id);
    } catch (e) {
      _movieInfo = null;   // Allow a retry to actually re-fetch instead of replaying the same rejected future
      rethrow;
    }
  }

  final MovieShowTimes movieShowTimes;

  final DataStream<ShowTimeSpec> selectedSpec;

  /// Simple cache for [getFormattedShowTimes]
  final _formattedShowTimes = <ShowTimeSpec, List<FormattedTheaterShowTimes>>{};

  /// List of [FormattedTheaterShowTimes] for this [filter].
  /// Memoized in memory per [filter].
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
