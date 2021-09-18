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
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MoviePage extends StatelessWidget {
  const MoviePage(this.movieShowTimes);
  
  final MovieShowTimes movieShowTimes;

  @override
  Widget build(BuildContext context) {
    const double contentPadding = 16;
    const double overlapContentHeight = 50;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          ScalingHeader(
            backgroundColor: Colors.red,
            title: Text(movieShowTimes.movie.title),
            flexibleSpace: CtCachedImage(
              path: movieShowTimes.movie.poster,
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
                    onPressed: movieShowTimes.movie.trailerId != null
                        ? () => navigateTo(context, (_) => TrailerPage(movieShowTimes.movie.trailerId!))
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
                    onPressed: () => launch(ApiClient.getMovieUrl(movieShowTimes.movie.id)),
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
                                  path: movieShowTimes.movie.poster,
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
                                  movieShowTimes.movie.title,
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                if (movieShowTimes.movie.directors != null)
                                  TextWithLabel(
                                    label: 'De',
                                    text: movieShowTimes.movie.directors!,
                                  ),
                                if (movieShowTimes.movie.actors != null)
                                  TextWithLabel(
                                    label: 'Avec',
                                    text: movieShowTimes.movie.actors!,
                                  ),
                                if (movieShowTimes.movie.genres != null)
                                  TextWithLabel(
                                    label: 'Genre',
                                    text: movieShowTimes.movie.genres!,
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (movieShowTimes.movie.releaseDate != null)
                                      TextWithLabel(
                                        label: 'Sortie',
                                        text: movieShowTimes.movie.releaseDateDisplay!,
                                      ),
                                    if (movieShowTimes.movie.duration != null)
                                      TextWithLabel(
                                        label: 'Durée',
                                        text: movieShowTimes.movie.duration!,
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
                          if (movieShowTimes.movie.pressRating != null)
                            _buildRatingWidget('Presse', movieShowTimes.movie.pressRating!),
                          if (movieShowTimes.movie.userRating != null)
                            _buildRatingWidget('Spectateur', movieShowTimes.movie.userRating!),
                        ],
                      ),

                      // Synopsis
                      AppResources.spacerMedium,
                      SynopsisWidget(
                        movieId: movieShowTimes.movie.id,
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
                          children: <Widget>[

                            // Title
                            Text(
                              'Séances',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Spacer(),

                            // Share Button
                            Tooltip(
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.shareAlt),
                                onPressed: () => Share.share(movieShowTimes.toFullString()),
                              ),
                              message: 'Partager les séances',
                            ),

                            // TODO add to calendar

                          ],
                        ),
                      ),


                      // Content
                      ...movieShowTimes.theatersShowTimes.map((theaterShowTimes) {
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

  void _openPoster(BuildContext context) => navigateTo(context, (_) => PosterPage(movieShowTimes.movie.poster));
}

class SynopsisWidget extends StatefulWidget {
  final ApiId movieId;

  const SynopsisWidget({Key? key, required this.movieId}) : super(key: key);

  @override
  _SynopsisWidgetState createState() => _SynopsisWidgetState();
}

class _SynopsisWidgetState extends State<SynopsisWidget> {
  static const collapsedMaxLines = 3;
  Future<String?>? fetchFuture;

  @override
  void initState() {
    fetchFuture = () async {
      debugPrint('fetch');
      await Future.delayed(Duration(seconds: 2));     //TODO remove
      //throw ExceptionWithMessage(message: 'Test');
      return (await AppService.api.getSynopsis(widget.movieId));
    } ();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: fetchFuture,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: AppResources.durationAnimationMedium,
          child: () {

            // Valid
            if (snapshot.hasData)
              return ShowMoreText(
                text: snapshot.data!,
                collapsedMaxLines: collapsedMaxLines,
              );

            // Loading
            return Stack(
              key: ValueKey(snapshot.hasError),   //For the AnimatedSwitcher to work
              children: <Widget>[

                // Fake empty text to set the Widget's height (equals to [collapsedMaxLines] time a text line height)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(collapsedMaxLines, (index) => Text(' ')),
                ),

                // Content that take the previous Column's height
                Positioned.fill(
                  child: () {

                    // If error
                    if (snapshot.hasError)
                      return IconMessage(
                        icon: IconMessage.iconError,
                        message: 'Impossible de récuperer le synopsis',
                        tooltip: snapshot.error.toString(),
                        inline: true,
                        redIcon: true,
                      );

                    // If loading, Draw fake animated lines
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Column(
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
                    );
                  } (),
                ),
              ],
            );
          } (),
        );
      }
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
          return Row(
            children: [
              // Time
              Text(
                showtime?.dateTime?.toTime.toString() ?? '-',
              ),

              // Tag
              if (showtime != null && showtime.version != null)
                TinyChip(
                  label: showtime.versionDisplay!,
                ),

              if (showtime != null && showtime.format != ShowFormat.f2D)
                TinyChip(
                  label: showtime.formatDisplay,
                ),

            ],
          );
        }).toList()..insertBetween(AppResources.spacerExtraTiny),

      ],
    );
  }
}
