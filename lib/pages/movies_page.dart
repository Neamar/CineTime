import 'dart:collection';
import 'dart:math';

import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage();

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> with BlocProvider<MoviesPage, MoviesPageBloc> {
  @override
  initBloc() => MoviesPageBloc();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (bloc.isSearchVisible.value == true) {
          _cancelSearch();
          return false;
        }
        return true;
      },
      child: ClearFocusBackground(
        child: Scaffold(    // Needed for background color
          body: FetchBuilder.basic<MoviesShowTimes>(
            controller: bloc.fetchController,
            fetchAtInit: false,
            task: bloc.fetch,
            builder: (context, moviesShowtimesData) {
              return Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: BehaviorSubjectBuilder<bool>(
                    subject: bloc.isSearchVisible,
                    builder: (context, snapshot) {
                      final isSearchVisible = snapshot.data!;

                      // Normal AppBar
                      if (!isSearchVisible) {
                        return AppBar(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Theater info
                              () {
                                final theaters = moviesShowtimesData.theaters;
                                final theatersCount = theaters.length;
                                return Text(
                                  () {
                                    if (theatersCount == 0) return 'Aucun cinéma sélectionné';
                                    if (theatersCount == 1) return 'Films pour ${theaters.first.name}';
                                    return 'Films dans $theatersCount cinémas';
                                  }(),
                                  style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              } (),

                              // Period
                              AppResources.spacerTiny,
                              Text(
                                moviesShowtimesData.periodDisplay,
                                style: Theme.of(context).textTheme.caption?.copyWith(color: AppResources.colorDarkGrey),
                              ),
                            ],
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(CineTimeIcons.pencil),
                              onPressed: _goToTheatersPage,
                            ),
                            IconButton(
                              icon: const Icon(CineTimeIcons.search),
                              onPressed: () => bloc.isSearchVisible.add(true),
                            ),
                            BehaviorSubjectBuilder<MovieSortType>(
                              subject: bloc.sortType,
                              builder: (context, snapshot) {
                                return _SortButton(
                                  value: snapshot.data!,
                                  onChanged: bloc.sortType.addDistinct,
                                );
                              },
                            ),
                          ],
                        );
                      }

                      // Search bar
                      else {
                        return AppBar(
                          title: TextField(
                            controller: bloc.searchController,
                            decoration: InputDecoration(
                              hintText: 'Filtrer par titre, acteurs, ...',
                              iconColor: Colors.white,
                              prefixIcon: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: _cancelSearch,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: bloc.searchController.clear,
                              ),
                            ),
                            autofocus: true,
                            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                            textInputAction: TextInputAction.search,
                          ),
                        );
                      }
                    },
                  ),
                ),
                body: () {
                  if (moviesShowtimesData.moviesShowTimes.isEmpty)
                    return const IconMessage(
                      icon: Icons.theaters,
                      message: 'Aucune séance',
                    );

                  return BehaviorSubjectBuilder<String>(
                    subject: bloc.search,
                    builder: (context, snapshot) {
                      return _FilteredMovieListView(
                        key: ObjectKey(moviesShowtimesData),    // Force complete rebuild on data refresh
                        moviesShowTimes: moviesShowtimesData.moviesShowTimes,
                        showTheaterName: moviesShowtimesData.theaters.length > 1,
                        search: snapshot.data,
                      );
                    },
                  );
                } (),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _goToTheatersPage() async {
    // Go to TheatersPage
    await navigateTo(context, (_) => const TheatersPage(), returnAfterPageTransition: false);

    // Update UI
    bloc.refresh(userAsked: true);
  }

  void _cancelSearch() {
    bloc.isSearchVisible.add(false);
    bloc.searchController.clear();
  }
}

class _SortButton extends StatelessWidget {
  static const _typesStrings = {
    MovieSortType.rating: 'Note',
    MovieSortType.releaseDate: 'Date de sortie',
    MovieSortType.duration: 'Durée',
  };

  const _SortButton({Key? key, required this.value, this.onChanged}) : super(key: key);

  final MovieSortType value;
  final ValueChanged<MovieSortType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieSortType>(
      icon: const Icon(Icons.sort),
      onSelected: onChanged,
      itemBuilder: (context) => MovieSortType.values.map((value) {
        return PopupMenuItem<MovieSortType>(
          value: value,
          textStyle: context.textTheme.subtitle1?.copyWith(color: this.value == value ? Theme.of(context).primaryColor : null),
          child: Text(
            _typesStrings[value]!,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _FilteredMovieListView extends StatefulWidget {
  const _FilteredMovieListView({
    Key? key,
    required this.moviesShowTimes,
    required this.showTheaterName,
    this.search,
  }) : super(key: key);

  final List<MovieShowTimes> moviesShowTimes;
  final bool showTheaterName;
  final String? search;

  @override
  _FilteredMovieListViewState createState() => _FilteredMovieListViewState();
}

class _FilteredMovieListViewState extends State<_FilteredMovieListView> {
  List<MovieShowTimes> filteredMoviesShowTimes = [];

  @override
  void initState() {
    super.initState();
    applyFilter();
  }

  void applyFilter() {
    setState(() {
      filteredMoviesShowTimes = () {
        if (isStringNullOrEmpty(widget.search)) return widget.moviesShowTimes;
        return widget.moviesShowTimes.where((mst) => mst.movie.matchSearch(widget.search!)).toList(growable: false);
      } ();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: filteredMoviesShowTimes.length,
      itemExtent: 100 * max(MediaQuery.of(context).textScaleFactor, 1.0),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final movieShowTimes = filteredMoviesShowTimes[index];
        return MovieCard(
          key: ObjectKey(movieShowTimes),
          movieShowTimes: movieShowTimes,
          showTheaterName: widget.showTheaterName,
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant _FilteredMovieListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.search != oldWidget.search) {
      applyFilter();
    }
  }
}


class MoviesPageBloc with Disposable {
  MoviesPageBloc() {
    // Initial fetch, after widget is initialised
    WidgetsBinding.instance!.addPostFrameCallback((_) => refresh());

    // Refresh on sort change
    sortType.skip(1).listen((value) {
      fetchController.refresh();
      AnalyticsService.trackEvent('Sort order', {
        'theatersId': _theaters.toIdListString(),
        'theaterCount': _theaters.length,
        'sortType': describeEnum(value),
      });
    });

    // Listen for search changes
    searchController.addListener(() => search.add(searchController.text));
  }

  UnmodifiableSetView<Theater> _theaters = UnmodifiableSetView(const {});
  final fetchController = FetchBuilderController<Never, MoviesShowTimes>();

  final isSearchVisible = BehaviorSubject.seeded(false);
  final searchController = TextEditingController();
  final search = BehaviorSubject<String>();

  final sortType = BehaviorSubject.seeded(MovieSortType.rating);

  Future<MoviesShowTimes> fetch() async {
    // Fetch data
    final moviesShowTimes = await AppService.api.getMoviesList(_theaters.toList(growable: false)..sort());

    // Sort
    moviesShowTimes.moviesShowTimes.sort((mst1, mst2) => mst1.compareTo(mst2, sortType.value!));

    // Analytics
    AnalyticsService.trackEvent('Movie list displayed', {
      'resultCount': moviesShowTimes.moviesShowTimes.length,
      'theaterCount': _theaters.length,
      'theatersId': _theaters.toIdListString(),
    });

    // Return data
    return moviesShowTimes;
  }

  void refresh({bool userAsked = false}) {
    // Compare new list with current one
    if (AppService.instance.selectedTheaters.isEqualTo(_theaters))
      return;

    // Analytics
    if (userAsked)
      AnalyticsService.trackEvent('Theater selected', {
        'count': AppService.instance.selectedTheaters.length - _theaters.length,
      });

    // Copy selected theater to a local list
    _theaters = UnmodifiableSetView(Set.from(AppService.instance.selectedTheaters));

    // Refresh data
    fetchController.refresh();
  }

  @override
  void dispose() {
    isSearchVisible.close();
    search.close();
    searchController.dispose();
    sortType.close();
    super.dispose();
  }
}