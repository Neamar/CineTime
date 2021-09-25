import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Scaffold(
      body: CustomScrollView(
        controller: bloc.scrollController,
        slivers: <Widget>[
          ScalingHeader(
            backgroundColor: Colors.red,
            title: Text(widget.movieShowTimes.movie.title),
            flexibleSpace: CtCachedImage(
              path: widget.movieShowTimes.movie.poster,
              onPressed: () => _openPoster(context),
              isThumbnail: false,
              applyDarken: true,
            ),
            overlapContentHeight: overlapContentHeight,
            overlapContentRadius: overlapContentHeight / 2,
            overlapContentBackgroundColor: Colors.redAccent,
            overlapContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FaIcon(
                          FontAwesomeIcons.video,
                          color: hasTrailer ? Colors.white : Colors.black26,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Bande annonce',
                          style: TextStyle(color: hasTrailer ? Colors.white : Colors.black26),
                        )
                      ],
                    ),
                    onPressed: hasTrailer
                        ? () => navigateTo(context, (_) => TrailerPage(widget.movieShowTimes.movie.trailerId!))
                        : null,
                  ),
                  TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FaIcon(
                          FontAwesomeIcons.externalLinkAlt,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Fiche',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                    onPressed: () => launch(ApiClient.getMovieUrl(widget.movieShowTimes.movie.id)),
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
                  padding: EdgeInsets.all(contentPadding).copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      // Movie info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GestureDetector(
                                onTap: () => _openPoster(context),
                                child: CtCachedImage(
                                  path: widget.movieShowTimes.movie.poster,
                                  isThumbnail: true,
                                ),
                              ),
                            ),
                          ),
                          AppResources.spacerMedium,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  widget.movieShowTimes.movie.title,
                                  style: Theme.of(context).textTheme.headline6,
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
                                    if (widget.movieShowTimes.movie.duration != null)
                                      TextWithLabel(
                                        label: 'Durée',
                                        text: widget.movieShowTimes.movie.duration!,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )
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
                    return CtAnimatedSwitcher(
                      child: Container(
                        key: ObjectKey(filter),
                        color: Colors.white,
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
                                    style: Theme.of(context).textTheme.headline6,
                                  ),

                                  // Filters
                                  AppResources.spacerSmall,
                                  Expanded(
                                    child: Center(
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
                                              onChanged: bloc.selectedSpec.add,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Share Button
                                  AppResources.spacerSmall,
                                  Tooltip(
                                    child: IconButton(
                                      icon: FaIcon(FontAwesomeIcons.shareAlt),
                                      onPressed: () => Share.share(widget.movieShowTimes.toFullString()),
                                    ),
                                    message: 'Partager les séances',
                                  ),

                                ],
                              ),
                            ),


                            // Content
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
                                        formattedShowTimes: theaterShowTimes.getFormattedShowTimes(filter),
                                        filterName: filter.toString(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                            AppResources.spacerMedium,

                          ],
                        ),
                      ),
                    );
                  }
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
                StarRating(
                  rating: rating,
                ),
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

  void _openPoster(BuildContext context) => navigateTo(context, (_) => PosterPage(widget.movieShowTimes.movie.poster));
}

class SynopsisWidget extends StatelessWidget {
  static const collapsedMaxLines = 3;

  const SynopsisWidget({Key? key, required this.movieId}) : super(key: key);

  final ApiId movieId;

  @override
  Widget build(BuildContext context) {
    return FetchBuilder<String>(
      task: () => AppService.api.getSynopsis(movieId),
      isDense: true,
      fetchingBuilder: (context) {
        return Stack(
          children: [
            // Fake empty text to set the Widget's height (equals to [collapsedMaxLines] time a text line height)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(collapsedMaxLines, (index) => Text(' ')),
            ),

            // Content that take the previous Column's height
            Positioned.fill(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(collapsedMaxLines, (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ],
        );
      },
      builder: (context, synopsis) {
        return ShowMoreText(
          text: synopsis,
          collapsedMaxLines: collapsedMaxLines,
        );
      },
    );
  }
}

class _TagFilterSelector extends StatelessWidget {
  const _TagFilterSelector({Key? key, required this.options, required this.selected, this.onChanged}) : super(key: key);

  final List<ShowTimeSpec> options;
  final ShowTimeSpec selected;
  final ValueChanged<ShowTimeSpec>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: options.map((option) => option == selected).toList(growable: false),
      constraints: BoxConstraints(minHeight: 0, minWidth: 0),
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
    Key? key,
    required this.theaterName,
    required this.formattedShowTimes,
    required this.filterName,
  }) : super(key: key);

  final String theaterName;
  final FormattedShowTimes formattedShowTimes;
  final String filterName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        // Theater name
        Text(
          theaterName,
          style: Theme.of(context).textTheme.headline6,
        ),

        // Showtimes
        AppResources.spacerSmall,
        if (formattedShowTimes.isNotEmpty)
          Row(
            children: formattedShowTimes.keys.mapIndexed<Widget>((index, day) {
              return _DayShowTimes(
                day: day,
                showtimes: formattedShowTimes[day]!,
                backgroundColor: () {
                  if (day == ApiClient.mockedNow.toDate) return Colors.redAccent;
                  if (index.isEven) return Colors.black12;
                } (),
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
  const _DayShowTimes({Key? key, required this.day, required this.showtimes, this.backgroundColor}) : super(key: key);

  final Date day;
  final List<ShowTime?> showtimes;
  final Color? backgroundColor;

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
            style: Theme.of(context).textTheme.subtitle1,
          ),

          // Day
          AppResources.spacerTiny,
          Text(
            day.day.toString(),
            style: Theme.of(context).textTheme.headline6,
          ),

        // Times
        AppResources.spacerSmall,
        ...showtimes.map<Widget>((showtime) {
          return Text(
            showtime?.dateTime.toTime.toString() ?? '-',
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
    selectedSpec.listen((value) {
      // If page is fully scrolled
      if (scrollController.offset == scrollController.position.maxScrollExtent) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: AppResources.durationAnimationMedium,
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  final scrollController = ScrollController();

  final BehaviorSubject<ShowTimeSpec> selectedSpec;

  @override
  void dispose() {
    selectedSpec.close();
    super.dispose();
  }
}