import 'dart:collection';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage([this.selectedTheaters]);

  final Iterable<Theater>? selectedTheaters;

  @override
  Widget build(BuildContext context) {
    return Provider<MoviesPageBloc>(
      create: (_) => MoviesPageBloc(selectedTheaters),
      dispose: (_, bloc) => bloc.dispose(),
      child: Scaffold(
        body: MoviesPageContent(),
      ),
    );
  }
}

class MoviesPageContent extends StatefulWidget {
  @override
  _MoviesPageContentState createState() => _MoviesPageContentState();
}

class _MoviesPageContentState extends State<MoviesPageContent> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bloc = Provider.of<MoviesPageBloc>(context);

    return BehaviorStreamBuilder<Iterable<MovieShowTimes>?>(
      subject: bloc.moviesShowTimes,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            // Header
            Material(
              color: Colors.red,
              child: InkWell(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        BehaviorStreamBuilder<SplayTreeSet<Theater>>(
                          subject: bloc.theaters,
                          builder: (context, snapshot) {
                            return Text('Films dans ${snapshot.data!.length} cinémas');
                          }
                        ),
                        if (bloc.filterHourEnabled)
                          Text('Entre ${bloc.filterHourMin}h et ${bloc.filterHourMax}h'),
                        if (bloc.filterRatingEnabled)
                          Text('Avec une note minimale de ${bloc.filterRatingMin} / 5'),
                      ],
                    ),
                  ),
                ),
                onTap: () => bloc.goToTheatersPage(context),
              ),
            ),

            // Content
            Expanded(
              child: EasyRefresh.custom(    // TODO try pull_to_refresh package instead ?
                controller: bloc.refresherController,
                scrollController: _scrollController,

                firstRefresh: true,
                header: ClassicalHeader(
                  refreshText: 'Tirez pour rafraichir',
                  refreshReadyText: 'Lachez pour rafraichir',
                  refreshingText: 'Chargement...',
                  refreshedText: 'Terminé',
                  refreshFailedText: 'Échec',
                  infoText: "Mis à jour à %T",
                ),
                firstRefreshWidget: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: SizedBox(
                      height: 200.0,
                      width: 300.0,
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 50.0,
                              height: 50.0,
                              child: SpinKitFadingCube(
                                color: Theme.of(context).primaryColor,
                                size: 25.0,
                              ),
                            ),
                            Container(
                              child: Text('Chargement'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                slivers: <Widget>[
                  () {
                    if (snapshot.hasError)
                      return SliverFillRemaining(
                        child: IconMessage(
                          icon: IconMessage.iconError,
                          message: 'Impossible de récuperer les données\n↓ Tirez pour re-essayer ↓',
                          tooltip: snapshot.error.toString(),
                          redIcon: true,
                        ),
                      );

                    if (!snapshot.hasData)
                      return SliverFillRemaining(
                        child: IconMessage(
                          icon: Icons.theaters,
                          message: 'Aucune séance',
                        ),
                      );

                    return SliverFixedExtentList(
                      itemExtent: 100,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var movieShowTimes = snapshot.data!.elementAt(index);

                          return MovieTile(
                            key: ValueKey(index),
                            movieShowTimes: movieShowTimes,
                            onPressed: () {
                              navigateTo<Iterable<Theater>>(context, (_) => Provider.value(    //TODO remove Provider ?
                                value: bloc,
                                child: MoviePage(
                                  movieShowTimes: movieShowTimes,
                                ),
                              ));
                            },
                          );
                        },
                        childCount: snapshot.data!.length,
                      ),
                    );
                  } (),
                ],
                onRefresh: bloc.fetch,
                bottomBouncing: false,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FilterPage extends StatefulWidget {   // TODO remove
  final double? pinnedSectionHeight;

  const FilterPage({Key? key, this.pinnedSectionHeight}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bloc = Provider.of<MoviesPageBloc>(context);

    return Column(
      children: <Widget>[

        // Theaters
        SizedBox(
          height: widget.pinnedSectionHeight,
          child: _FilterSection(
            title: 'Cinémas',
            child: Row(
              children: [
                Expanded(
                  child: BehaviorStreamBuilder<Iterable<Theater>>(
                    subject: bloc.theaters,
                    builder: (context, snapshot) {
                      var theaters = snapshot.data;
                      if (theaters?.isNotEmpty != true)
                        return Text('Aucun cinéma selectioné');

                      return Wrap(
                        children: theaters!.map((t) => _TheaterChip(
                          name: t.name,
                          isFavorite: bloc.favoriteTheaters!.isFavorite(t),
                          onDeleted: () => bloc.removeTheater(t),
                        )).toList(growable: false),
                      );
                    }
                  ),
                ),
                Tooltip(
                  child: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => bloc.goToTheatersPage(context),
                  ),
                  message: 'Ajouter un cinéma',
                ),
                Tooltip(
                  child: IconButton(
                    icon: Icon(Icons.stars),
                    onPressed: bloc.applyFavorite,
                  ),
                  message: 'Cinémas favoris',
                ),
              ],
            ),
          ),
        ),

        // Hours
        /** TODO remove ?
        _FilterSection(
          title: 'Horaires',
          child: FlutterSlider(
            values: [bloc.filterHourMin.toDouble(), bloc.filterHourMax.toDouble()],
            rangeSlider: true,
            min: MoviesPageBloc.DefaultFilterHourMin.toDouble(),
            max: MoviesPageBloc.DefaultFilterHourMax.toDouble(),
            step: FlutterSliderStep(
              step: 1,
            ),
            tooltip: FlutterSliderTooltip(
              format: (value) => '${double.parse(value).toInt()}h',
            ),
            onDragCompleted: (_, lowerValue, upperValue) => bloc.updateHourFilter(lowerValue, upperValue),
          ),
        ),*/

        // Rating
        _FilterSection(
          title: 'Note',
          child: Row(
            children: <Widget>[
              Text('Note minimal'),
              SmoothStarRating(
                allowHalfRating: false,
                rating: bloc.filterRatingMin,
                onRatingChanged: bloc.updateRatingFilter,
              ),
            ],
          ),
        ),

        // Attributes
        _FilterSection(
          title: 'Attributs',
          child: Text('Filter par attributes (VO/VF)'),
        ),

        // Dev
        /*_FilterSection(
          title: 'Paramètres',
          child: BehaviorStreamBuilder<bool>(
            subject: bloc.isDevModeEnabled,
            builder: (context, snapshot) {
              return SwitchListTile(
                title: Text('Mode developpeur'),
                value: snapshot.data!,
                onChanged: bloc.isDevModeEnabled.add,
              );
            },
          ),
        ),*/

        // Results
        Expanded(
          child: BehaviorStreamBuilder<Iterable<MovieShowTimes>?>(
            subject: bloc.moviesShowTimes,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FilterSection(
                    title: 'Résultats',
                    child: Text('${snapshot.data?.length ?? 0}'),
                  ),
                  Expanded(
                    child: _MoviePosters(
                      movies: snapshot.data,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _FilterSection extends StatelessWidget {
  final String? title;
  final Widget? child;

  const _FilterSection({Key? key, this.title, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          color: Colors.redAccent,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              title!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: child,
        ),
      ],
    );
  }
}

class _TheaterChip extends StatelessWidget {
  final String? name;
  final bool? isFavorite;
  final VoidCallback? onDeleted;

  const _TheaterChip({Key? key, this.name, this.isFavorite, this.onDeleted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Chip(
        label: Text(name!),
        backgroundColor: isFavorite! ? Colors.yellow : null,
        deleteIcon: Icon(Icons.close),
        onDeleted: onDeleted,
      ),
    );
  }
}

class _MoviePosters extends StatelessWidget {
  final Iterable<MovieShowTimes>? movies;
  final _random = Random();

  _MoviePosters({Key? key, this.movies}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (movies?.isNotEmpty != true)
      return SizedBox();

    return LayoutBuilder(
      builder: (context, constrains) {
        return Stack(
          children: movies!.map((m) {
            return Positioned(
              left: _random.nextDouble() * constrains.maxWidth,
              top: _random.nextDouble() * constrains.maxHeight,
              child: Transform.rotate(
                alignment: Alignment.center,
                angle: _random.nextDouble() * pi - pi / 2,
                child: CachedNetworkImage(
                  imageUrl: ApiClient.getImageUrl(m.movie.poster, isThumbnail: true)!,
                  placeholder: (_, url) => CtProgressIndicator(),
                  errorWidget: (_, __, ___) => SizedBox(),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}


class MoviesPageBloc with Disposable {
  final theaters = BehaviorSubject<SplayTreeSet<Theater>>();
  final favoriteTheaters = FavoriteTheatersHandler.instance;

  final refresherController = EasyRefreshController();
  bool _useCacheOnNextFetch = false;
  late MoviesShowTimes _theatersShowTimes;     // Fetched data
  final moviesShowTimes = BehaviorSubject<Iterable<MovieShowTimes>?>();    // Filtered & sorted list
  Object? _moviesShowTimesError;     //Workaround while BehaviorSubject.hasError isn't exposed : https://github.com/ReactiveX/rxdart/pull/397

  static const DefaultFilterHourMin = 0;
  static const DefaultFilterHourMax = 24;
  int filterHourMin = DefaultFilterHourMin;
  int filterHourMax = DefaultFilterHourMax;
  bool get filterHourEnabled => filterHourMin != DefaultFilterHourMin || filterHourMax != DefaultFilterHourMax;

  static const double DefaultFilterRatingMin = 0;
  double filterRatingMin = DefaultFilterRatingMin;
  bool get filterRatingEnabled => filterRatingMin != DefaultFilterRatingMin;

  MoviesPageBloc(Iterable<Theater>? selectedTheaters)  {
    // Init list with the favorites
    //TODO instead of a forced alphabetical sorting, add a reorderable list for the favorites ?
    theaters.add(SplayTreeSet.from(selectedTheaters ?? favoriteTheaters!.theaters, (t1, t2) => t1.name.compareTo(t2.name)));

    // Update data when theaters list change
    theaters.listen((value) {
      _useCacheOnNextFetch = true;
      refresherController.callRefresh();
    });

    // TODO remove when https://github.com/ReactiveX/rxdart/pull/397 is closed
    moviesShowTimes.stream.listen(null, onError: (error) => _moviesShowTimesError = error);
  }

  removeTheater(Theater t) {
    theaters.add(theaters.value..remove(t));
  }

  void goToTheatersPage(BuildContext context) async {
    // Go to TheatersPage
    var selectedTheaters = await navigateTo<Iterable<Theater>>(context, (_) => TheatersPage(selectedTheaters: theaters.value));
    if (selectedTheaters == null)
      return;

    // Add result to selection & Update UI
    theaters.add(theaters.value..clear()..addAll(selectedTheaters));
  }

  void applyFavorite() {
    theaters.add(theaters.value..clear()..addAll(favoriteTheaters!.theaters));
  }

  Future<void> fetch() async {
    // Reset displayed list if needed
    if (_moviesShowTimesError != null)
      moviesShowTimes.add(_moviesShowTimesError = null);

    // If theaters list is empty
    if (theaters.valueOrNull?.isNotEmpty != true) {
      moviesShowTimes.add(null);
      return;
    }

    // Fetch data
    try {
      //TODO handle cache
      _theatersShowTimes = await AppService.api.getMoviesList(theaters.value, useCache: _useCacheOnNextFetch);
    } catch (e, s) {
      moviesShowTimes.addError(e);
      return;
    } finally {
      _useCacheOnNextFetch = false;
    }

    // Update UI
    applyFilterAndSort();
  }

  void updateHourFilter(num lowerValue, num upperValue) {
    filterHourMin = lowerValue.toInt();
    filterHourMax = upperValue.toInt();
    applyFilterAndSort();
  }

  void updateRatingFilter(double rating) {
    filterRatingMin = rating;
    applyFilterAndSort();
  }

  void applyFilterAndSort() {
    final displayList = <MovieShowTimes>[];

    // ---- Filter ----
    final movieRelatedFilterEnabled = filterRatingEnabled;
    final deepFilterEnabled = filterHourEnabled;
    final areFiltersEnabled = movieRelatedFilterEnabled || deepFilterEnabled;

    for (final movieShowTimes in _theatersShowTimes.moviesShowTimes!) {
      movieShowTimes.filteredTheatersShowTimes.clear();

      // If there is deep-data-related filters
      if (deepFilterEnabled) {
        for (final theaterShowTimes in movieShowTimes.theatersShowTimes) {
          final filteredShowTimes = theaterShowTimes.showTimes.where((showTime) {
            final time = showTime.dateTime!.toTime;
            return time.hour >= filterHourMin && time.hour <= filterHourMax;
          });

          if (filteredShowTimes.isNotEmpty)
            movieShowTimes.filteredTheatersShowTimes.add(
              theaterShowTimes.copyWith(showTimes: filteredShowTimes.toList(growable: false)),
            );
        }
      }

      if (!areFiltersEnabled || (
            (movieShowTimes.movie.rating == null || movieShowTimes.movie.rating! >= filterRatingMin) &&
            (!deepFilterEnabled || movieShowTimes.filteredTheatersShowTimes.isNotEmpty))) {
        displayList.add(movieShowTimes);
      }
    }

    // ---- Sort ----
    //TODO displayList.sort();

    // ---- Update UI ----
    moviesShowTimes.add(displayList);
  }

  @override
  void dispose() {
    theaters.close();
    moviesShowTimes.close();
    super.dispose();
  }
}