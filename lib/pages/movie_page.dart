import 'package:cinetime/models/_models.dart';
import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/web_services.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/helpers/tools.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO Make each show day & time selectable to allow selective share, and a button "ajouter la séance à mon calendrier"
class MoviePage extends StatefulWidget {
  final MovieShowTimes movieShowTimes;

  const MoviePage({Key? key, required this.movieShowTimes}) : super(key: key);

  @override
  _MoviePageState createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final _horizontalScrollController = ScrollController();

  final areShowtimesFiltered = BehaviorSubject.seeded(true);

  @override
  Widget build(BuildContext context) {
    const double contentPadding = 16;
    const double overlapContentHeight = 50;
    final bloc = Provider.of<MoviesPageBloc>(context);    //TODO remove ?

    return Scaffold(
      //backgroundColor: Colors.blueGrey,
      body: CustomScrollView(
        slivers: <Widget>[
          ScalingHeader(
            backgroundColor: Colors.red,
            title: Text(widget.movieShowTimes.movie.title),
            flexibleSpace: CtCachedImage(
              path: widget.movieShowTimes.movie.poster,
              onPressed: () => navigateTo(context, () => PosterPage(widget.movieShowTimes.movie.poster)),
              isThumbnail: false,
              applyDarken: true,
            ),
            overlapContentHeight: overlapContentHeight,
            overlapContentRadius: overlapContentHeight / 2,
            overlapContentBackgroundColor: Colors.redAccent,
            overlapContent: Row(
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
                  onPressed: widget.movieShowTimes.movie.trailerCode != null
                      ? () => navigateTo(context, () => TrailerPage(widget.movieShowTimes.movie.trailerCode!))
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
                        style: TextStyle(color: Colors.white)
                      )
                    ],
                  ),
                  onPressed: () => launch(WebServices.getMovieUrl(widget.movieShowTimes.movie.code)),
                )
              ],
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
                              child: CtCachedImage(
                                path: widget.movieShowTimes.movie.poster,
                                isThumbnail: true,
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
                                    TextWithLabel(
                                      label: 'Durée',
                                      text: widget.movieShowTimes.movie.durationDisplay,
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
                        movieCode: widget.movieShowTimes.movie.code,
                      ),

                    ],
                  ),
                ),

                // Show times
                AppResources.spacerMedium,
                BehaviorStreamBuilder<bool>(
                  subject: areShowtimesFiltered,
                  builder: (context, snapshot) {
                    var applyFilter = snapshot.data == true;
                    var theatersShowTimesDisplay = widget.movieShowTimes.getTheatersShowTimesDisplay(applyFilter);

                    return Material(
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

                                // Filter Button
                                Tooltip(
                                  child: IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.filter,
                                      color: applyFilter ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => areShowtimesFiltered.add(!applyFilter),
                                  ),
                                  message: 'Filtres ${applyFilter ? 'appliqués' : 'ignorés'}',
                                ),

                                // Share Button
                                Tooltip(
                                  child: IconButton(
                                    icon: FaIcon(FontAwesomeIcons.shareAlt),
                                    onPressed: () => Share.share(widget.movieShowTimes.toFullString(applyFilter)),
                                  ),
                                  message: 'Partager les séances',
                                ),

                                // TODO add to calendar

                              ],
                            ),
                          ),


                          // Content
                          ...theatersShowTimesDisplay.map((theaterShowTimes) {
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
              title
            ),
            AppResources.spacerSmall,
            Row(
              children: <Widget>[
                StarRating(
                  rating: rating,
                ),
                AppResources.spacerSmall,
                Text(
                  rating.toStringAsFixed(1)
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    areShowtimesFiltered.close();
    super.dispose();
  }
}

class SynopsisWidget extends StatefulWidget {
  final String movieCode;

  const SynopsisWidget({Key? key, required this.movieCode}) : super(key: key);

  @override
  _SynopsisWidgetState createState() => _SynopsisWidgetState();
}

class _SynopsisWidgetState extends State<SynopsisWidget> {
  static const collapsedMaxLines = 3;
  Future<String?>? fetchFuture;

  @override
  void initState() {
    fetchFuture = () async {
      print('fetch');
      await Future.delayed(Duration(seconds: 2));     //TODO remove
      //throw ExceptionWithMessage(message: 'Test');
      return (await WebServices.getSynopsis(widget.movieCode));
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
  final TheaterShowTimes theaterShowTimes;

  const TheaterShowTimesWidget({Key? key, required this.theaterShowTimes}) : super(key: key);

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
          ].insertBetween(AppResources.spacerSmall),
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
              if (showtime != null) ...[
                AppResources.spacerTiny,
                ...showtime.tags.map((tag) => TinyChip(
                  label: tag,
                )).toList(growable: false),
              ],

            ],
          );
        }).toList()..insertBetween(AppResources.spacerExtraTiny),

      ],
    );
  }
}
