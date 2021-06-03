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
import 'package:scaling_header/scaling_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO Make each show day & time selectable to allow selective share, and a button "ajouter la séance à mon calendrier"
class MoviePage extends StatefulWidget {
  final MovieShowTimes movieShowTimes;

  const MoviePage({Key key, this.movieShowTimes}) : super(key: key);

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
                  onPressed: () => navigateTo(context, () => TrailerPage(widget.movieShowTimes.movie.trailerCode)),
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
                          AppResources.WidgetSpacerMedium,
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
                                    text: widget.movieShowTimes.movie.directors,
                                  ),
                                if (widget.movieShowTimes.movie.actors != null)
                                  TextWithLabel(
                                    label: 'Avec',
                                    text: widget.movieShowTimes.movie.actors,
                                  ),
                                TextWithLabel(
                                  label: 'Genre',
                                  text: widget.movieShowTimes.movie.genres,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (widget.movieShowTimes.movie.releaseDate != null)
                                      TextWithLabel(
                                        label: 'Sortie',
                                        text: widget.movieShowTimes.movie.releaseDateDisplay,
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
                      AppResources.WidgetSpacerMedium,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (widget.movieShowTimes.movie.pressRating != null)
                            _buildRatingWidget('Presse', widget.movieShowTimes.movie.pressRating),
                          if (widget.movieShowTimes.movie.userRating != null)
                            _buildRatingWidget('Spectateur', widget.movieShowTimes.movie.userRating),
                        ],
                      ),

                      // Synopsis
                      AppResources.WidgetSpacerMedium,
                      SynopsisWidget(
                        movieCode: widget.movieShowTimes.movie.code,
                      ),

                    ],
                  ),
                ),

                // Show times
                AppResources.WidgetSpacerMedium,
                BehaviorStreamBuilder<bool>(
                  subject: areShowtimesFiltered,
                  builder: (context, snapshot) {
                    var applyFilter = snapshot.data == true;
                    var theatersShowTimesDisplay = widget.movieShowTimes.getTheatersShowTimesDisplay(applyFilter);

                    return Material(
                      color: Color(0xFFEFEFEF),
                      child: Column(
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
                          LayoutBuilder(
                            builder: (context, box) {
                              return FadingEdgeScrollView.fromSingleChildScrollView(
                                gradientFractionOnEnd: 0.2,     //TODO remove fade if content is too small. see https://github.com/mponkin/fading_edge_scrollview/issues/4
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: box.maxWidth),
                                    child: Padding(
                                      padding: const EdgeInsets.all(contentPadding),
                                      child: IntrinsicWidth(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: theatersShowTimesDisplay.map((theaterShowTimes) {
                                            return TheaterShowTimesWidget(
                                              theaterShowTimes: theaterShowTimes,
                                            );
                                          }).toList(growable: false),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
            AppResources.WidgetSpacerSmall,
            Row(
              children: <Widget>[
                StarRating(
                  rating: rating,
                ),
                AppResources.WidgetSpacerSmall,
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

  const SynopsisWidget({Key key, this.movieCode}) : super(key: key);

  @override
  _SynopsisWidgetState createState() => _SynopsisWidgetState();
}

class _SynopsisWidgetState extends State<SynopsisWidget> {
  static const collapsedMaxLines = 3;
  Future<String> fetchFuture;

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
    return FutureBuilder<String>(
      future: fetchFuture,
      builder: (context, snapshot) {
        return AnimatedSwitcher(
          duration: AppResources.DurationAnimationMedium,
          child: () {

            // Valid
            if (snapshot.hasData)
              return ShowMoreText(
                text: snapshot.data,
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
                      baseColor: Colors.grey[300],
                      highlightColor: Colors.grey[100],
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

  const TheaterShowTimesWidget({Key key, this.theaterShowTimes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              theaterShowTimes.theater.name,
              style: Theme.of(context).textTheme.headline6,
            ),
            ...List.generate(theaterShowTimes.roomsShowTimes.length, (index) => _buildRoomSection(
                context, theaterShowTimes.roomsShowTimes[index]
            ))
          ].insertBetween(AppResources.WidgetSpacerSmall),
        ),
      ),
    );
  }

  Widget _buildRoomSection(BuildContext context, RoomShowTimes roomShowTimes) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          // Room info
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[

                if (roomShowTimes.screen != null)
                  Text(
                    'Salle ${roomShowTimes.screen}',
                    style: Theme.of(context).textTheme.caption,
                  ),

                if (roomShowTimes.seatCount != null && roomShowTimes.seatCount > 1)
                  Text(
                    '${roomShowTimes.seatCount} sièges',
                    style: Theme.of(context).textTheme.caption,
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: roomShowTimes.tags.map((tag) => TinyChip(
                    label: tag,
                  )).toList(growable: false),
                ),
              ].insertBetween(AppResources.WidgetSpacerExtraTiny),
            ),
          ),

          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              color: Colors.grey,
              width: 2,
            ),
          ),

          // Show times
          /** LayoutGrid version.  TODO remove ?
          Expanded(
            child:
              () {
                var lines = roomShowTimes.showTimesDisplay;

                return LayoutGrid(
                  templateRowSizes: List.generate(lines.length, (_) => IntrinsicContentTrackSize()),
                  templateColumnSizes: List.generate(lines.first.length, (_) => IntrinsicContentTrackSize()),
                  gridFit: GridFit.loose,
                  columnGap: 8,
                  rowGap: 2,
                  children: lines
                      .expand((line) => line)
                      .map((text) {
                        var child = Text(text ?? '-');
                        if (text != null)
                          return child;
                        return Center(
                          child: child,
                        );
                      })
                      .toList(growable: false),
                );
              } (),
          ),*/

          ...() {
            var lines = roomShowTimes.showTimesDisplay;

            return List<Widget>.generate(lines.first.length, (column) {
              return Column(
                crossAxisAlignment: column == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: lines.map<Widget>((line) => Text(line[column] ?? '-')).toList()
                  ..insertBetween(AppResources.WidgetSpacerExtraTiny),
              );
            })..insertBetween(AppResources.WidgetSpacerTiny)
              ..insert(1, Expanded(
                  child: AppResources.WidgetSpacerMedium
              ));
          } (),
        ],
      ),
    );
  }
}
