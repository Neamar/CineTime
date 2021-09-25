import 'dart:collection';
import 'dart:math';

import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage([this.selectedTheaters]);

  final Iterable<Theater>? selectedTheaters;

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> with BlocProvider<MoviesPage, MoviesPageBloc> {
  final _scrollController = ScrollController();

  @override
  initBloc() => MoviesPageBloc(widget.selectedTheaters);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BehaviorSubjectBuilder<Iterable<MovieShowTimes>?>(
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
                      child: BehaviorSubjectBuilder<SplayTreeSet<Theater>>(   //OPTI because BehaviorSubjectBuilder of moviesShowTimes is above, and theses two streams are linked, this BehaviorSubjectBuilder is useless. Maybe rework bloc archi ?
                        subject: bloc.theaters,
                        builder: (context, snapshot) {
                          final theaters = snapshot.data;
                          final theatersCount = theaters?.length ?? 0;
                          return Text(
                            () {
                              if (theatersCount == 0) return 'Aucun cinéma sélectionné';
                              if (theatersCount == 1) return 'Films pour ${theaters!.first.name}';
                              return 'Films dans $theatersCount cinémas';
                            } (),
                            textAlign: TextAlign.center,
                          );
                        },
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
                  onRefresh: bloc.fetch,
                  bottomBouncing: false,
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
                            message: 'Impossible de récupérer les données\n↓ Tirez pour re-essayer ↓',
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
                        itemExtent: 100 * max(MediaQuery.of(context).textScaleFactor, 1.0),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return MovieTile(
                              key: ValueKey(index),
                              movieShowTimes: snapshot.data!.elementAt(index),
                              showTheaterName: bloc.theaters.value.length > 1,
                            );
                          },
                          childCount: snapshot.data!.length,
                        ),
                      );
                    } (),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class MoviesPageBloc with Disposable {
  final theaters = BehaviorSubject<SplayTreeSet<Theater>>();
  final favoriteTheaters = FavoriteTheatersHandler.instance;

  final refresherController = EasyRefreshController();
  bool _useCacheOnNextFetch = false;
  late MoviesShowTimes _theatersShowTimes;     // Fetched data
  final moviesShowTimes = BehaviorSubject<Iterable<MovieShowTimes>?>();    // Sorted list

  MoviesPageBloc(Iterable<Theater>? selectedTheaters)  {
    // Init list with the favorites
    theaters.add(SplayTreeSet.from(selectedTheaters ?? favoriteTheaters!.theaters, (t1, t2) => t1.name.compareTo(t2.name)));

    // Update data when theaters list change
    theaters.listen((value) {
      _useCacheOnNextFetch = true;
      refresherController.callRefresh();
    });
  }

  void goToTheatersPage(BuildContext context) async {
    // Go to TheatersPage
    var selectedTheaters = await navigateTo<Iterable<Theater>>(context, (_) => TheatersPage(selectedTheaters: theaters.value));
    if (selectedTheaters == null)
      return;

    // Add result to selection & Update UI
    theaters.add(theaters.value..clear()..addAll(selectedTheaters));
  }

  Future<void> fetch() async {
    // Reset displayed list if needed
    if (moviesShowTimes.hasError)
      moviesShowTimes.add(null);

    // If theaters list is empty
    if (theaters.valueOrNull?.isNotEmpty != true) {
      moviesShowTimes.add(null);
      return;
    }

    // Fetch data
    try {
      _theatersShowTimes = await AppService.api.getMoviesList(theaters.value, useCache: _useCacheOnNextFetch);
    } catch (e, s) {
      reportError(e, s); // Do not await
      if (!moviesShowTimes.isClosed)
        moviesShowTimes.addError(e);
      return;
    } finally {
      _useCacheOnNextFetch = false;
    }

    // Update UI
    applySort();
  }

  void applySort() {
    final displayList = _theatersShowTimes.moviesShowTimes!;

    // ---- Sort ----
    displayList.sort((mst1, mst2) => (mst2.movie.userRating ?? 0).compareTo(mst1.movie.userRating ?? 0));

    // ---- Update UI ----
    moviesShowTimes.tryAdd(displayList);
  }

  @override
  void dispose() {
    theaters.close();
    moviesShowTimes.close();
    super.dispose();
  }
}