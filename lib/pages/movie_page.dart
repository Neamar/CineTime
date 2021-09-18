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

    return Scaffold(
      body: CustomScrollView(
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
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Bande annonce',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                    onPressed: widget.movieShowTimes.movie.trailerId != null
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
                Material(
                  color: Color(0xFFEFEFEF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      // Header
                      Padding(
                        padding: const EdgeInsets.all(contentPadding).copyWith(bottom: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[

                            // Title
                            Text(
                              'Séances',
                              style: Theme.of(context).textTheme.headline6,
                            ),

                            // Filters
                            AppResources.spacerSmall,
                            BehaviorSubjectBuilder<ShowTimeSpec>(
                              subject: bloc.selectedSpec,
                              builder: (context, snapshot) {
                                return _TagFilterSelector(
                                  options: bloc.showTimeSpecOptions,
                                  selected: snapshot.data!,
                                  onChanged: bloc.selectedSpec.add,
                                );
                              }
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
                            controller: ScrollController(),
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal:  contentPadding),
                                child: TheaterShowTimesWidget(
                                  theaterShowTimes: theaterShowTimes,
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
  const TheaterShowTimesWidget({Key? key, required this.theaterShowTimes}) : super(key: key);

  final TheaterShowTimes theaterShowTimes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            // Theater name
            Text(
              theaterShowTimes.theater.name,
              style: Theme.of(context).textTheme.headline6,
            ),

            // Showtimes
            Row(
              children: theaterShowTimes.formattedShowTimes!.keys.map<Widget>((day) => _buildDaySection(
                context, day, theaterShowTimes.formattedShowTimes![day]!,
              )).toList()..insertBetween(AppResources.spacerSmall),
            ),
          ]..insertBetween(AppResources.spacerSmall),
        ),
      ),
    );
  }

  Widget _buildDaySection(BuildContext context, Date day, List<ShowTime?> showtimes) {
    return Column(
      children: [
        // Day
        Text(
          day.toWeekdayString(withDay: true)!,
        ),

        // Times
        AppResources.spacerSmall,
        ...showtimes.map<Widget>((showtime) {
          return Text(
            showtime?.dateTime?.toTime.toString() ?? '-',
          );
        }).toList()..insertBetween(AppResources.spacerExtraTiny),

      ],
    );
  }
}


class MoviePageBloc with Disposable {
  MoviePageBloc(this.movieShowTimes) {
    // Build filter options
    showTimeSpecOptions = [
      ShowTimeSpec(ShowVersion.dubbed, ShowFormat.f2D),
      ShowTimeSpec(ShowVersion.original, ShowFormat.f2D),
      ShowTimeSpec(ShowVersion.dubbed, ShowFormat.f3D),
    ];

    selectedSpec.add(showTimeSpecOptions.first);
  }

  final MovieShowTimes movieShowTimes;

  late List<ShowTimeSpec> showTimeSpecOptions;
  final selectedSpec = BehaviorSubject<ShowTimeSpec>();

  @override
  void dispose() {
    selectedSpec.close();
    super.dispose();
  }
}

class ShowTimeSpec {
  const ShowTimeSpec(this.version, this.format);

  final ShowVersion version;
  final ShowFormat format;

  @override
  String toString() => version.toDisplayString() + (format != ShowFormat.f2D ? ' ${format.toDisplayString()}' : '');
}